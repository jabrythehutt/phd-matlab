/*
* =============================================================
* cdi_varlist.c
* This is a MEX-file for MATLAB to enable the use of the CDI library.
* It has to be compile against the CDI library and the NetCDF library.

To create the MEX files, type the lines beginning with "mex..." in the MATLAB command prompt.
HOW TO CREATE cdi_varlist?
	mex cdi_varlist.c cdi_mx.c -Iinclude -Llib64 -lcdi -lnetcdf
WARNING: This file is also use to create cdi_readall MEX file in combination with cdi_readall.c

	/include/ directory must contain cdi.h and grib.h files.
	/lib64/ must contain libcdi.a and libnetcdf.a libraries.
% add the -DDOUBLE flag to return double value for field data returned by cdi_readall, cdi_readfield, cdi_readfull
% add the -DDEBUG flag to display debug info
* =============================================================
*/

#include "mex.h"
#include <stdio.h>
#include "cdi.h"
#include "cdi_mx.h"

#ifdef READALL
void cdi_varlist(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[])
{
    const char *fieldnames[] = {FIELD_VARID, /* this field is not meant to be visible, it is the ID in the file */
        FIELD_VARCODE, /* this field is not meant to be visible, it is the ID in the file */
        FIELD_VARNAME,
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
		FIELD_GRIB_LEV, /* optional */
        FIELD_DATA};
	int nfields = 15;
    mxArray *pGRIBCode;
    double *pGRIDCodeData;
#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[])
{
    const char *fieldnames[] = {FIELD_VARNAME,
		FIELD_LONG_NAME,
		FIELD_UNITS,
		FIELD_GRIB_PAR, /* optional */
		FIELD_GRIB_TYP, /* optional */
		FIELD_GRIB_LEV}; /* optional */
	int nfields = 6;
#endif
	int nametableLength = 0, nametableRow = 0;

	int vlistID, streamID, nVars, varID, grib_par, gridID, zaxisID;
	int gridType, zaxisType;
	bool isGRIB = false;
	mxArray *pTmpMxArray, *pNametable = NULL;
    int foundVariableNb = 0;
    int variableNb = 0;

	/* Check for proper number of arguments. */
	if (nrhs != 2)
		mexErrMsgTxt("2 inputs are required: (filename, nametable).");

	/* ------------ FILENAME ------------ */
	streamID = OpenCDIStream(prhs[0]);

	/* ------------ NAMETABLE ------------ */
	if (streamInqFiletype(streamID) == FILETYPE_GRB)
	{
        isGRIB = true;
		if (nrhs == 2 && !mxIsEmpty(prhs[1])) /* nametable is given and not empty */
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

	/* Get the variable list of the dataset */
	vlistID = streamInqVlist(streamID);

	/* get number of variables */
	nVars = vlistNvars(vlistID);

	/* create a 1xN struct matrix for output  */
	plhs[0] = mxCreateStructMatrix(1, getNumberOfVariables(streamID), nfields, fieldnames);

    if (!isGRIB)
    {
        /* the grib_par, grib_typ and grib_lev fields are not required */
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_PAR));
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_LEV));
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_GRIB_TYP));
    }

    /* ==============================================================================*/
	for (varID = 0; varID < nVars; varID++)
	{
        DEBUG_DISPLAY("\n================= #%d/%d =========================\n",varID+1, nVars);
		if (isGRIB)
		{
            int levelsize = 0;
            int levelID = 0;

			grib_par = vlistInqVarCode(vlistID, varID); /* grib code */

			zaxisID = vlistInqVarZaxis(vlistID, varID);
			DEBUG_DISPLAY("zaxisID = %d\n", zaxisID);

			levelsize = zaxisInqSize(zaxisID);
			DEBUG_DISPLAY("levelsize = %d\n", levelsize);

			for ( levelID = 0; levelID < levelsize; levelID++)
			{
				int grib_typ, grib_lev, level2;
				getLevel(zaxisID, levelID, &grib_typ, &grib_lev, &level2);
    			mxSetField(plhs[0], variableNb, FIELD_GRIB_PAR, mxCreateDoubleScalar((double) grib_par));
				mxSetField(plhs[0], variableNb, FIELD_GRIB_TYP, mxCreateDoubleScalar((double) grib_typ));
				mxSetField(plhs[0], variableNb, FIELD_GRIB_LEV, mxCreateDoubleScalar((double) grib_lev));
                if (nametableLength <= 0) /* No nametable: read info from the file */
					getInfoFromFile(vlistID, varID, plhs, variableNb);
				else
                {
					if (replaceInfoFromTablename(vlistID, varID, grib_par, grib_typ, grib_lev, plhs, variableNb, pNametable, nametableLength))
                        foundVariableNb++;
                }

#ifdef READALL
                mxSetField(plhs[0], variableNb, FIELD_VARID, mxCreateDoubleScalar((double) varID));/* this field is not meant to be visible, it is the ID in the file */
                pGRIBCode = mxCreateDoubleMatrix(1, 3, mxREAL);
                pGRIDCodeData = mxGetPr(pGRIBCode);
                pGRIDCodeData[0] = grib_par;
                pGRIDCodeData[1] = grib_typ;
                pGRIDCodeData[2] = grib_lev;
				mxSetField(plhs[0], variableNb, FIELD_VARCODE, pGRIBCode); /* this field is not meant to be visible, it is used for cdi_readall */
                readmeta(vlistID, varID, streamID, plhs, variableNb, pGRIBCode, NULL);
#endif
                variableNb++;

                DEBUG_DISPLAY("grib_par = %d\n",grib_par);
                DEBUG_DISPLAY("grib_typ = %d\n", grib_typ );
                DEBUG_DISPLAY("grib_lev = %d\nlevels: (%d, %d)\n",  grib_lev, grib_lev, level2);
                DEBUG_DISPLAY("zaxisInqLevel = %d\n", zaxisInqLevel(zaxisID, levelID));
               /* DEBUG_DISPLAY("zaxisInqLbound = %d\n", zaxisInqLbound(zaxisID, levelID));
                DEBUG_DISPLAY("zaxisInqUbound = %d\n", zaxisInqUbound(zaxisID, levelID));*/
                DEBUG_DISPLAY("----------------------\n");
			}
		}
		/* --------------------------------------------------------------------------*/
		else /* isGRIB */
		{
			getInfoFromFile(vlistID, varID, plhs, variableNb);
#ifdef READALL
            mxSetField(plhs[0], variableNb, FIELD_VARID, mxCreateDoubleScalar((double) varID));/* this field is not meant to be visible, it is the ID in the file */
    		mxSetField(plhs[0], variableNb, FIELD_VARCODE,
                mxDuplicateArray(mxGetField(plhs[0], variableNb, FIELD_VARNAME))); /* this field is not meant to be visible, it is used for cdi_readall */
            readmeta(vlistID, varID, streamID, plhs, variableNb, NULL, NULL );
#endif
            variableNb++;
		}
	} /* for all variables */
	/* ==============================================================================*/

    if (variableNb != foundVariableNb && nametableLength > 0)
    {
    	char buf[MEXCDI_STR_LEN];
        sprintf(buf, "%d variables in the file. %d found in the nametable.", variableNb, foundVariableNb);
        mexWarnMsgTxt(buf);
    }
#if !defined(READALL)
    /* remove the field used only internally */
    mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_VARID));
#endif
	streamClose(streamID);

	if (pNametable != NULL)
		mxDestroyArray(pNametable);

}



