/*
* =============================================================
* cdi_read1var.c
* This is a MEX-file for MATLAB to enable the use of the CDI library.
* It has to be compile against the CDI library and the NetCDF library.

To create the MEX files, type the lines beginning with "mex..." in the MATLAB command prompt.
HOW TO CREATE cdi_readfull?
	mex cdi_read1var.c cdi_mx.c -Iinclude -Llib64 -lcdi -lnetcdf -output cdi_readfull -DREADFULL
HOW TO CREATE cdi_readmeta?
	mex cdi_read1var.c cdi_mx.c -Iinclude -Llib64 -lcdi -lnetcdf -output cdi_readmeta -DREADMETA
HOW TO CREATE cdi_readfield?
	mex cdi_read1var.c cdi_mx.c -Iinclude -Llib64 -lcdi -lnetcdf -output cdi_readfield -DREADFIELD

	/include/ directory must contain cdi.h and grib.h files.
	/lib64/ must contain libcdi.a and libnetcdf.a libraries.
% add the -DDOUBLE flag to return double value for field data returned by cdi_readall, cdi_readfield, cdi_readfull
% add the -DDEBUG flag to display debug info
* =============================================================
*/

#ifdef READFULL
#define READMETA
#define READFIELD
#endif

#include "mex.h"
#include <stdio.h>
#include "cdi.h"
#include "cdi_mx.h"

#if defined(READALL)
void read1var(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[])
#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[])
#endif
{
#ifdef READMETA
    const char *fieldnames[] = {FIELD_VARNAME,
		FIELD_LONG_NAME,
		FIELD_UNITS,
        FIELD_LON,
        FIELD_LAT,
        FIELD_NORTHPOLE_LON, /* optional */
        FIELD_NORTHPOLE_LAT, /* optional */
        FIELD_LEVELS,
        FIELD_DATES,
		FIELD_GRIB_PAR, /* optional */
		FIELD_GRIB_TYP, /* optional */
#ifdef READFULL
		FIELD_GRIB_LEV, /* optional */
        FIELD_DATA};
	int nfields = 13;
#else
		FIELD_GRIB_LEV}; /* optional */
	int nfields = 12;
#endif
#endif
	mxArray *pNametable = NULL;
	mxArray *pVarname = NULL;
    const mxArray *pTime = NULL;
    bool isGRIB = false;
    bool useGRIB;
	int nametableLength = 0;
	int vlistID, streamID, nVars, varID = -1;
    bool varnameToDestroy = false;
    double *pGrib = NULL;

    /* ==================================================================*/
    /* CHECKING INPUTS
    /* ==================================================================*/
	/* Check for proper number of arguments. */
	if (nrhs < 3)
		mexErrMsgTxt("3 inputs are required (filename, nametable, varname).");
#ifdef READFIELD
	if (nrhs > 4)
		mexErrMsgTxt("The inputs are: (filename, nametable, varname [, time]).");
#endif

	/* ------------ FILENAME ------------ */
	streamID = OpenCDIStream(prhs[0]);

	/* ------------ NAMETABLE ------------ */
	if (streamInqFiletype(streamID) == FILETYPE_GRB)
	{
        isGRIB = true;
		if (prhs[1] != NULL && !mxIsEmpty(prhs[1])) /* nametable is not empty */
		{
			nametableLength = GetGribTable(prhs[1], &pNametable);
 		}
        else
            mexWarnMsgTxt("No nametable specified for the GRIB file.");
	}
    else
    {
        isGRIB = false;
    }

	/* Input 3, varname / GRIBcode, must be a string or numeric. */
	if (mxIsChar(prhs[2]))
    {
        if (isGRIB && nametableLength > 0)
        {
            useGRIB = true;
            pVarname = getGRIBByName(prhs[2], pNametable);
            if (pVarname == NULL)
            {
				/* varname not found in nametable: discard nametable */
		    	mxDestroyArray(pNametable);
		    	pNametable = NULL;
				nametableLength = 0;
	            varnameToDestroy = false;
				useGRIB = false;
				pVarname = (mxArray *)prhs[2];
			}
            else
	            varnameToDestroy = true;
        }
        else
        {
            useGRIB = false;
        	pVarname = (mxArray *)prhs[2];
        }
    }
	else if (mxIsNumeric(prhs[2]))
    {
        useGRIB = true;
		pVarname = (mxArray *)prhs[2];
    }
	else
		mexErrMsgTxt("Input 3 must a string (varname) or a matrix ([grib_par, grib_typ, grib_lev]) for GRIB files.");

#if defined(READFIELD)
	/* Input 4, time, must be numeric. */
	if (nrhs == 4)
	{
		if (mxIsNumeric(prhs[3]) != 1)
			mexErrMsgTxt("Input 4, timestep, must be numeric.");
        pTime = prhs[3];
	}
    else
    {
        pTime = NULL;
    }
#endif

    /* Get the variable list of the dataset */
	vlistID = streamInqVlist(streamID);

    /* ==================================================================*/
    /* CHECKING THE VARIABLE
    /* ==================================================================*/
	/* Search for the correct variable */
	if (useGRIB) /* search according to GRIB code */
	{
		varID = getVarIDByGRIB((const mxArray *)pVarname, vlistID);
		if (varID < 0) /* variable not found */
		{
			if (varnameToDestroy)
			{
				/* Original input was varname string: retry without nametable */
				mxDestroyArray(pVarname);
				varnameToDestroy = false;
				useGRIB = false;
				pVarname = (mxArray *)prhs[2];
			}
			else
			{
				/* Original input was GRIB code: give up */
				mexErrMsgTxt("Variable not found.");
			}
		}
	}

	if (varID < 0) /* Variable not found yet: search by name */
		varID = getVarIDByName((const mxArray *)pVarname, vlistID);

	if (varID < 0) /* variable still not found: give up */
		mexErrMsgTxt("Variable not found.");

#ifdef READMETA
    /* ==================================================================*/
    /* META META META META META META META META META META META META META */
    /* ==================================================================*/
    /* ==================================================================*/
    /* READING INFO
    /* ==================================================================*/
    /* create a 1xN struct matrix for output  */
	plhs[0] = mxCreateStructMatrix(1, 1, nfields, fieldnames);

    pGrib = mxGetData(pVarname);
    if (useGRIB)
    {
        mxSetField(plhs[0], 0, FIELD_GRIB_PAR, mxCreateDoubleScalar(pGrib[0]));
        mxSetField(plhs[0], 0, FIELD_GRIB_TYP, mxCreateDoubleScalar(pGrib[1]));
        mxSetField(plhs[0], 0, FIELD_GRIB_LEV, mxCreateDoubleScalar(pGrib[2]));
        DEBUG_DISPLAY("%d %d %d\n", pGrib[0], pGrib[1], pGrib[2]);
    }
    else
    {
        /* the grib_par, grib_typ and grib_lev fields are not required */
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_PAR));
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_LEV));
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_TYP));
    }

    if (nametableLength <= 0) /* No nametable: read info from the file */
        getInfoFromFile(vlistID, varID, plhs, 0);
    else
        replaceInfoFromTablename(vlistID, varID, pGrib[0], pGrib[1], pGrib[2], plhs, 0, pNametable, nametableLength);

    /* ==================================================================*/
    /* READING METADATA
    /* ==================================================================*/
    readmeta(vlistID, varID, streamID, plhs, 0, pVarname, pTime);

#endif /* of READMETA */

#ifdef READFIELD
    /* ==================================================================*/
    /* READFIELD READFIELD READFIELD READFIELD READFIELD READFIELD READF */
    /* ==================================================================*/
{
    mxArray *pDataArray = NULL;
    int T, X, Y, Z;
    mwSize dims[4];

    /* ==================================================================*/
    /* ALLOCATING OUTPUT
    /* ==================================================================*/
	getTimeSize(pTime, streamID, &T ); /* Notice: T is the same for all variables */
	getSize(vlistID, varID, streamID, useGRIB, &X, &Y, &Z);

	dims[0] = X;
	dims[1] = Y;
	dims[2] = Z;
	dims[3] = T;

	/*	If the function is called with a non-NULL left-hand-side argument,
		we write the field data directly to the given array */
	if ( plhs[0]  != NULL
        && mxGetNumberOfElements(plhs[0]) == X*Y*Z*T )
	{
        DEBUG_DISPLAY("Memory already allocated.\n");
		pDataArray = plhs[0];
	}
	else
	{
		/* allocate memory for MATLAB matrix*/
		allocateField(useGRIB, vlistID, varID, streamID, T, dims, &pDataArray);
	}

    /* ==================================================================*/
    /* READING FIELD
    /* ==================================================================*/
    /* read the variable data for all times or specified time */
    readField(pTime, useGRIB, streamID, vlistID, varID, &pDataArray, pVarname, dims);
#if defined(READFULL)
	mxSetField(plhs[0], 0, FIELD_DATA, pDataArray);
#elif defined(READFIELD)
	plhs[0] = pDataArray;
#endif
}
#endif /* of READFIELD */

    if (varnameToDestroy && pVarname != NULL)
        mxDestroyArray(pVarname);

    if (pNametable != NULL)
    	mxDestroyArray(pNametable);

	streamClose(streamID);
}

