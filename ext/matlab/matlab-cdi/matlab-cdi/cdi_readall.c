/*
* =============================================================
* cdi_readall.c 
* This is a MEX-file for MATLAB to enable the use of the CDI library.
* It has to be compile against the CDI library and the NetCDF library.

To create the MEX files, type this line in the MATLAB command prompt:
mex cdi_readall.c cdi_varlist.c cdi_read1var.c cdi_mx.c -Iinclude -Llib64 -lcdi -lnetcdf -output cdi_readall -DREADALL -DREADFIELD

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

void cdi_varlist(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[]);

void cdi_read1var(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[]);


void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
				 const mxArray *prhs[])
{
    mxArray *pDataArray;
	int i, nVariables = -1;
	int nFields;
    int T;
	mwSize dims[4];
    int streamID, vlistID, nVars;
    bool useGRIB;
	char buf[MEXCDI_STR_LEN];
	
    /* ==================================================================*/
    /* Call CDI_VARLIST */
    /* ==================================================================*/
    cdi_varlist(1, plhs, nrhs, prhs);

    streamID = OpenCDIStream(prhs[0]);
    useGRIB = streamInqFiletype(streamID) == FILETYPE_GRB;
	/* Get the variable list of the dataset */
	vlistID = streamInqVlist(streamID);
	/* get number of variables */
    nVariables = mxGetNumberOfElements(plhs[0]);

    /* ==================================================================*/
    /* ALLOCATING ALL MEMORY FOR FIELD
    /* ==================================================================*/
	getTimeSize(NULL, streamID, &T ); /* Notice: T is the same for all variables */
	for (i=0; i<nVariables; i++)
	{
        DEBUG_DISPLAY("allocating %d/%d\n", i+1, nVariables);
		/* get size of data to read */
		dims[0] = (mwSize)mxGetNumberOfElements(mxGetField(plhs[0], i, FIELD_LON)); 
		dims[1] = (mwSize)mxGetNumberOfElements(mxGetField(plhs[0], i, FIELD_LAT));
		dims[2] = (mwSize)mxGetNumberOfElements(mxGetField(plhs[0], i, FIELD_LEVELS));
		dims[3] = (mwSize)mxGetNumberOfElements(mxGetField(plhs[0], i, FIELD_DATES));
        /* allocate memory for MATLAB matrix*/
		allocateField(useGRIB, vlistID, (int)mxGetScalar(mxGetField(plhs[0], i, FIELD_VARID)), streamID, T, dims, &pDataArray); 
        DEBUG_DISPLAY("setting %d/%d\n", i+1, nVariables);
        mxSetField(plhs[0], (mwIndex)i, FIELD_DATA, pDataArray); 
	}

    /* ==================================================================*/
	/* CALL CDI_READFIELD FOR EACH VARIABLE */
    /* ==================================================================*/
	for (i=0; i<nVariables; i++)
	{
		/* Prepare data for CDI_READFIELD */
		mxArray *plhsTmp[1];
		const mxArray *prhsTmp[3];

		/* Filename, nametable */
		prhsTmp[0] = prhs[0];
        if (nrhs == 2)
    		prhsTmp[1] = prhs[1]; /* if nametable */
        else
            prhsTmp[1] = NULL;

		/* Varname: plhs[0] holds thee output from cdi_readmeta */
		prhsTmp[2] = mxGetField(plhs[0], i, FIELD_VARCODE);

		/* pass previously allocated data as left-hand-side argument to cdi_readfield*/
		plhsTmp[0] = mxGetField(plhs[0], i, FIELD_DATA);

		/* Call CDI_READFIELD */
		read1var(1, plhsTmp, 3, prhsTmp);
	}

    /* remove the fields used only internally */
    mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_VARCODE));
    mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_VARID));
    
	streamClose(streamID);
}

