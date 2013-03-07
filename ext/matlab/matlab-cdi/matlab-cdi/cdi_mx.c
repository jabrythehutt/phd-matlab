/*
* =============================================================
* cdi_mx.c
* This is a MEX-file for MATLAB to enable the use of the CDI library.
* =============================================================
*/

#include "cdi_mx.h"
#include "cdi.h"
#include "grib.h"

#include <string.h>

/* =============================================================
field structure names
==============================================================*/
const char FIELD_VARID[] = "id"; /* INTERNAL USE ONY */
const char FIELD_VARCODE[] = "code"; /* INTERNAL USE ONY */
const char FIELD_VARNAME[] = "varname";
const char FIELD_LONG_NAME[] = "long_name";
const char FIELD_UNITS[] = "units";
const char FIELD_GRIB_PAR[] = "grib_par";
const char FIELD_GRIB_TYP[] = "grib_typ";
const char FIELD_GRIB_LEV[] = "grib_lev";
const char FIELD_LON[] = "lon";
const char FIELD_LAT[] = "lat";
const char FIELD_NORTHPOLE_LON[] = "northpole_lon";
const char FIELD_NORTHPOLE_LAT[] = "northpole_lat";
const char FIELD_LEVELS[] = "levels";
const char FIELD_DATES[] = "dates";
const char FIELD_DATA[] = "data";

/* =============================================================
convert a matrix into another type
INPUT
	inoutMatrix: matrix MATLAB in old type
	MATLABConversionFunctionName: string of the MATLAB new type name
OUPUT
	inoutMatrix: matrix MATLAB in old type
RETURN
==============================================================*/
void conversion(mxArray *inoutMatrix[], char *MATLABConversionFunctionName)
{
    mxArray *outArray;
	char buf[MEXCDI_STR_LEN];

    DEBUG_DISPLAY("Conversion to \"%s\"\n", MATLABConversionFunctionName);
    if (0 != mexCallMATLAB(1, &outArray, 1, inoutMatrix, MATLABConversionFunctionName))
    {
        sprintf(buf, "mexCallMATLAB failed with \"%s\".", MATLABConversionFunctionName);
		mexErrMsgTxt(buf);
    }
    mxDestroyArray(inoutMatrix[0]);
    DEBUG_DISPLAY("Conversion finished\n");

    inoutMatrix[0] = outArray;
}

/* =============================================================
read the nametable file and returns a cell array
INPUT
	mxFilename: MATRIX input of the filename
OUPUT
	nametable: cell array from the nametable
RETURN
	length of the cell array
==============================================================*/
int GetGribTable(const mxArray *mxFilename, mxArray **nametable)
{
	mxArray *lhs;
	mxArray *prhs[4];
	mxArray *pTmpMxArray;
	int i, cellArrayLen;

	/* Fopen file */
	prhs[0] = mxDuplicateArray(mxFilename);
	prhs[1] = mxCreateString("rt");
    mexCallMATLAB(1, &lhs, 2, prhs, "fopen");
	for (i=0; i<2; i++)
		mxDestroyArray(prhs[i]);

    if (mxGetScalar(lhs) == -1)
		mexErrMsgTxt("Opening nametable failed.");
	/* Scan text */
	prhs[0] = mxDuplicateArray(lhs);
    mxDestroyArray(lhs);
	prhs[1] = mxCreateString("%d%d%d%s%s%s");
	prhs[2] = mxCreateString("HeaderLines");
	prhs[3] = mxCreateDoubleScalar(0.0);

    if ( mexCallMATLAB(1, &lhs, 4, prhs, "textscan") != 0)
	{
		mexCallMATLAB(0, NULL, 1, prhs, "fclose");
		for (i=0; i<4; i++)
			mxDestroyArray(prhs[i]);
		mexErrMsgTxt("Scanning nametable file failed.");
	}

    for (i=1; i<4; i++) /* don't destroy file pointer */
		mxDestroyArray(prhs[i]);

	/* Close file */
	if (mexCallMATLAB(0, NULL, 1, prhs, "fclose") != 0)
    {
        mxDestroyArray(lhs);
        mxDestroyArray(prhs[0]);
		mexErrMsgTxt("Closing nametable file failed.");
    }

    mxDestroyArray(prhs[0]);
	/* Get lengths of nametable cells */
	pTmpMxArray = mxGetCell((const mxArray*)lhs, 0);
	cellArrayLen = (int) mxGetNumberOfElements(pTmpMxArray);
    
	if (6 != mxGetNumberOfElements(lhs) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 0)) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 1)) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 2)) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 3)) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 4)) 
        || mxIsEmpty(mxGetCell((const mxArray*)lhs, 5)) ) 
	{
        mxDestroyArray(lhs);
		mexErrMsgTxt("Could not read nametable file: invalid file.");
	}

	*nametable = lhs;

	return cellArrayLen;
}

/* =============================================================
retrieve the varID of a variable according to its GRIB code (grib_par grib_typ grib_lev)
INPUT
	pGRIBcode: MATLAB matrix of the grib code [grib_par grib_typ grib_lev]
	vlistID: list ID from the CDI library
OUPUT
RETURN
	varID needed by the CDI library
==============================================================*/
int getVarIDByGRIB(const mxArray *pGRIBcode, int vlistID)
{
	int varID, levelID;
	mxArray *pTmpMxArray = NULL;
	int *pGRIBdata;
	int varCode; /* , gridType, zaxisType; */
	char buf[MEXCDI_STR_LEN];

	int nVars = vlistNvars(vlistID);
    bool found = false;

    DEBUG_DISPLAY("getVarIDByGRIB\n");
	/* Search according to GRIBcode */
	if (mexCallMATLAB(1, &pTmpMxArray, 1, (mxArray **)&pGRIBcode, "int32") != 0)
		mexErrMsgTxt("Could not convert GRIBcode to int32");
	if (mxGetNumberOfElements(pTmpMxArray) != 3)
		mexErrMsgTxt("GRIB code must be array of 1-by-3");
	pGRIBdata = mxGetData(pTmpMxArray);

	for (varID = 0; varID < nVars; varID++)
	{
		/* Get variable parameters */
		varCode	= vlistInqVarCode(vlistID, varID);

		if (varCode == pGRIBdata[0])
		{
            int zaxisID = vlistInqVarZaxis(vlistID, varID);
            int levelsize = zaxisInqSize(zaxisID);

            DEBUG_DISPLAY("Searching [%d, %d, %d]\n", pGRIBdata[0], pGRIBdata[1], pGRIBdata[2]);
            for ( levelID = 0; levelID < levelsize; levelID++)
            {
                int grib_typ, grib_lev, level2;
                getLevel(zaxisID, levelID, &grib_typ, &grib_lev, &level2);
                if (grib_typ == pGRIBdata[1] && grib_lev == pGRIBdata[2])
                {
                    found = true;
                    DEBUG_DISPLAY("Finding [%d, %d, %d], varID = %d\n", pGRIBdata[0], grib_typ, grib_lev, varID);
                    break;
                }
            }
		}

        if (found)
            break;
	}
	if (!found)
	{
		varID = -1;
		sprintf(buf, "Variable [%d %d %d] not found in data file.\n", pGRIBdata[0], pGRIBdata[1], pGRIBdata[2]);
		mexWarnMsgTxt(buf);
	}

	return varID;
}

/* =============================================================
retrieve the varID of a variable according to its name
INPUT
	pVarname: MATLAB input of the variable name
	vlistID: list ID from the CDI library
OUPUT
RETURN
	varID needed by the CDI library
==============================================================*/
int getVarIDByName(const mxArray *pVarname, int vlistID)
{
	int varID, buflen, status;
	char szVarName[MEXCDI_STR_LEN];
	char buf[MEXCDI_STR_LEN];
	char warnBuf[MEXCDI_STR_LEN];

	int nVars = vlistNvars(vlistID);
    DEBUG_DISPLAY("getVarIDByName\n");
	buflen = (int) mxGetNumberOfElements(pVarname) + 1;
    status = mxGetString(pVarname, buf, buflen);
    if (status != 0)
    {
        mexErrMsgTxt("The variable name is too long. Not enough space.");
    }

    for (varID = 0; varID < nVars; varID++)
    {
        vlistInqVarName(vlistID, varID, szVarName);
        if (strcmp(szVarName, buf) == 0)
        {
            break;
        }
    }
    if (varID >= nVars)
    {
		varID = -1;
        sprintf(warnBuf, "Variable %s not found in the data file.\n", buf);
        mexWarnMsgTxt(warnBuf);
    }

	return varID;
}

/* =============================================================
retrieve the GRIB code (grib_par grib_typ grib_lev) according to its name
INPUT
	pVarname: MATLAB input of the variable name
	nametable: cell array from the nametable
OUPUT
RETURN
	pGRIBcode: MATLAB matrix of the grib code [grib_par grib_typ grib_lev]
==============================================================*/
mxArray* getGRIBByName(const mxArray* pVarname, const mxArray *nametable)
{
	char varnameInFile[MEXCDI_STR_LEN];
    char _pgrib_name[MEXCDI_STR_LEN];
	mxArray *pmxRetval = NULL;
	double *pRetvalData = NULL;
	mxArray *pmxgrib_name;
	mxArray *pgrib_name;
	int nametableRow;
	int nametableLength;

	int buflen = (int) mxGetNumberOfElements(pVarname) + 1;
    if (0 != mxGetString(pVarname, _pgrib_name, buflen))
    {
        mexErrMsgTxt("The variable name is too long. Not enough space.");
    }

    DEBUG_DISPLAY("getGRIBByName\n");
	pmxgrib_name= mxGetCell((const mxArray*)nametable, 3);
    nametableLength = (int) mxGetNumberOfElements(pmxgrib_name);

	/* Find match */
	for (nametableRow = 0; nametableRow < nametableLength; nametableRow++)
	{
		pgrib_name = mxGetCell((const mxArray*)pmxgrib_name, nametableRow);
        buflen = (int) mxGetNumberOfElements(pgrib_name) + 1;
        if (0 != mxGetString(pgrib_name, varnameInFile, buflen))
        {
            mexErrMsgTxt("The variable name is too long. Not enough space.");
        }

        DEBUG_DISPLAY("Comparing with string \"%s\"\n", varnameInFile);
        if (strcmp(varnameInFile, _pgrib_name) == 0)
			break;
	}

	if (nametableRow >= nametableLength)
	{
    	char buf[MEXCDI_STR_LEN];
		sprintf(buf, "Variable %s not found in the nametable.\n", _pgrib_name);
		mexWarnMsgTxt(buf);
		return NULL;
	}

	{
		mwSize ndim = 2;
		mwSize dims[2] = {1, 3};
		pmxRetval = mxCreateDoubleMatrix(1, 3, 0);
	}

	/* Get data from nametable to array to be returned */
	pRetvalData	= mxGetPr(pmxRetval);
	{
		mxArray *pmxgrib_par, *pmxgrib_typ, *pmxgrib_lev;
    	int *pgrib_par, *pgrib_typ, *pgrib_lev;
        pmxgrib_par	= mxGetCell((const mxArray*)nametable, 0);
        pgrib_par	= mxGetData(pmxgrib_par);
        pmxgrib_typ	= mxGetCell((const mxArray*)nametable, 1);
        pgrib_typ   = mxGetData(pmxgrib_typ);
        pmxgrib_lev	= mxGetCell((const mxArray*)nametable, 2);
        pgrib_lev	= mxGetData(pmxgrib_lev);

        pRetvalData[0] = pgrib_par[nametableRow];
        pRetvalData[1] = pgrib_typ[nametableRow];
        pRetvalData[2] = pgrib_lev[nametableRow];
	}

	return pmxRetval;
}

/* =============================================================
check and open a file
INPUT
	mxFilename: MATLAB input of the filename
OUPUT
RETURN
	CDI stream ID
==============================================================*/
int OpenCDIStream(const mxArray *mxFilename)
{
	int  buflen, status;
	int	 streamID;
	char *szInputFilename;

	/* Input 1 must be a string. */
	if (mxIsChar(mxFilename) != 1)
		mexErrMsgTxt("Input must be a string.");

	/* Get the length of the input string. */
	buflen = (int)(mxGetM(mxFilename) * mxGetN(mxFilename)) + 1;

	if (buflen == 1)
		mexErrMsgTxt("First input must not be empty.");

	/* Allocate memory for szInputFilename string */
	szInputFilename = mxCalloc(buflen, sizeof(char));
	{
		/* Copy the string data from prhs[0] into a C string */
		status = mxGetString(mxFilename, szInputFilename, buflen);
		if (status != 0)
			mexErrMsgTxt("The filename is too long. Not enough space.");

		/* Open the dataset */
		streamID = streamOpenRead(szInputFilename);
		if ( streamID < 0 )
		{
			mxFree(szInputFilename);
			mexErrMsgIdAndTxt("cdi_library:streamOpenRead", cdiStringError(streamID));
		}
	}
	mxFree(szInputFilename);

	return streamID;
}

/* =============================================================
retrieve the level
INPUT
	zaxisID: CDI z axis ID
	levelID: CDI level ID
OUPUT
	outLongLevelType: level type from international convention
	outLevel1: value of level 1
	outLevel2: value of level 2
RETURN
NOTES: this function is a copy-paste of an internal CDI function
==============================================================*/
 void getLevel(int zaxisID, int levelID, int *outLongLevelType, int *outLevel1, int *outLevel2)
 {
	 static char func[] = "getLevel";
	 double level;
	 int ilevel, leveltype, ltype;
	 static int warning = 1;
	 static int vct_warning = 1;

	 leveltype = zaxisInqType(zaxisID);
	 ltype = zaxisInqLtype(zaxisID);

/*	 if ( leveltype == ZAXIS_GENERIC )
	 {
		 leveltype = ZAXIS_PRESSURE;
	 } */

	 switch (leveltype)
	 {
	 case ZAXIS_SURFACE:
		 {
			 *outLongLevelType = LTYPE_SURFACE;
			 *outLevel1    = (int) zaxisInqLevel(zaxisID, levelID);
			 *outLevel2    = 0;
			 break;
		 }
	 case ZAXIS_HYBRID:
		 {
			 if ( zaxisInqLbounds(zaxisID, NULL) && zaxisInqUbounds(zaxisID, NULL) )
			 {
				 *outLongLevelType = LTYPE_HYBRID_LAYER;
				 *outLevel1    = (int) zaxisInqLbound(zaxisID, levelID);
				 *outLevel2    = (int) zaxisInqUbound(zaxisID, levelID);
			 }
			 else
			 {
				 *outLongLevelType = LTYPE_HYBRID;
				 *outLevel1    = (int) zaxisInqLevel(zaxisID, levelID);
				 *outLevel2    = 0;
			 }
			 break;
		 }
	 case ZAXIS_PRESSURE:
		 {
			 double dum;
			 char units[128];

			 level = zaxisInqLevel(zaxisID, levelID);
			 if ( level < 0 )
				 Warning(func, "pressure level of %f Pa is below 0.", level);

			 zaxisInqUnits(zaxisID, units);
			 if ( strncmp(units, "hPa", 3) == 0 ||  strncmp(units, "mb",2 ) == 0 )
				 level = level*100;

			 ilevel = (int) level;
			 if ( level < 32768 && (level < 100 || modf(level/100, &dum) > 0) )
			 {
				 *outLongLevelType = LTYPE_99;
				 *outLevel1    = ilevel;
				 *outLevel2    = 0;
			 }
			 else
			 {
				 *outLongLevelType = LTYPE_ISOBARIC;
				 *outLevel1    = ilevel/100;
				 *outLevel2    = 0;
			 }
			 break;
		 }
	 case ZAXIS_HEIGHT:
		 {
			 level = zaxisInqLevel(zaxisID, levelID);

			 ilevel = (int) level;
			 *outLongLevelType = LTYPE_HEIGHT;
			 *outLevel1    = ilevel;
			 *outLevel2    = 0;

			 break;
		 }
	 case ZAXIS_ALTITUDE:
		 {
			 level = zaxisInqLevel(zaxisID, levelID);

			 ilevel = (int) level;
			 *outLongLevelType = LTYPE_ALTITUDE;
			 *outLevel1    = ilevel;
			 *outLevel2    = 0;

			 break;
		 }
	 case ZAXIS_DEPTH_BELOW_LAND:
		 {
			 if ( zaxisInqLbounds(zaxisID, NULL) && zaxisInqUbounds(zaxisID, NULL) )
			 {
				 *outLongLevelType = LTYPE_LANDDEPTH_LAYER;
				 *outLevel1    = (int) zaxisInqLbound(zaxisID, levelID);
				 *outLevel2    = (int) zaxisInqUbound(zaxisID, levelID);
			 }
			 else
			 {
				 level = zaxisInqLevel(zaxisID, levelID);

				 ilevel = (int) level;
				 *outLongLevelType = LTYPE_LANDDEPTH;
				 *outLevel1    = ilevel;
				 *outLevel2    = 0;
			 }

			 break;
		 }
	 case ZAXIS_DEPTH_BELOW_SEA:
		 {
			 level = zaxisInqLevel(zaxisID, levelID);

			 ilevel = (int) level;
			 *outLongLevelType = LTYPE_SEADEPTH;
			 *outLevel1    = ilevel;
			 *outLevel2    = 0;

			 break;
		 }
	 case ZAXIS_ISENTROPIC:
		 {
			 level = zaxisInqLevel(zaxisID, levelID);

			 ilevel = (int) level;
			 *outLongLevelType = 113;
			 *outLevel1    = ilevel;
			 *outLevel2    = 0;

			 break;
		 }
         case ZAXIS_GENERIC:
                 {
                         level = zaxisInqLevel(zaxisID, levelID);

                         ilevel = (int) level;
                         *outLongLevelType = ltype;
                         *outLevel1    = ilevel;
                         *outLevel2    = 0;

                         break;
                 }
	 default:
		 {
			 mxErrMsgTxt(func, "leveltype >%s< unsupported", zaxisNamePtr(leveltype));
			 break;
		 }
	 }
 }

 /* =============================================================
retieve basic variable info from file
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	index: index of the MATLAB structure to update
OUPUT
	plhs: updated MATLAB structure of variable info
RETURN
==============================================================*/
void getInfoFromFile(int vlistID, int varID, mxArray *plhs[], int index )
{
	char szTmp[MEXCDI_STR_LEN];

    /* Varname */
	vlistInqVarName(vlistID, varID, szTmp);
    DEBUG_DISPLAY("varname: %s\n", szTmp);
	mxSetField(plhs[0], index, FIELD_VARNAME, mxCreateString((const char*)szTmp));

	/* long_name */
	vlistInqVarLongname(vlistID, varID, szTmp);
    DEBUG_DISPLAY("long_name: %s\n", szTmp);
	mxSetField(plhs[0], index, FIELD_LONG_NAME, mxCreateString((const char*)szTmp));

	/* units */
	vlistInqVarUnits(vlistID, varID, szTmp);
    DEBUG_DISPLAY("units: %s\n", szTmp);
	mxSetField(plhs[0], index, FIELD_UNITS, mxCreateString((const char*)szTmp));
}

 /* =============================================================
replace the basic variable info from nametable
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	grib_par: GRIB par
	grib_typ: GRIB type
	grib_lev: GRIB level
	index: index of the MATLAB structure to update
	pNametable: MATLAB cell array of info from nametable
	nametableLength: length of the cell array
OUPUT
	plhs: updated MATLAB structure of variable info
RETURN
	true if the variable can be found in the nametable, else false
==============================================================*/
bool replaceInfoFromTablename(int vlistID, int varID, int grib_par, int grib_typ, int grib_lev, mxArray *plhs[], int index, const mxArray* pNametable, int nametableLength)
{
	char buf[MEXCDI_STR_LEN];
	mxArray *pTmpMxArray;
    bool outResult = false;
    int nametableRow;
	mxArray *pmxgrib_par, *pmxgrib_typ, *pmxgrib_lev;
	int *pgrib_par, *pgrib_typ, *pgrib_lev;

    /* nametable is loaded, so we get strings from that one */
	pmxgrib_par	= mxGetCell((const mxArray*)pNametable, 0);
	pgrib_par	= mxGetData(pmxgrib_par);
	pmxgrib_typ	= mxGetCell((const mxArray*)pNametable, 1);
	pgrib_typ   = mxGetData(pmxgrib_typ);
	pmxgrib_lev	= mxGetCell((const mxArray*)pNametable, 2);
	pgrib_lev	= mxGetData(pmxgrib_lev);

	/* Find match */
	for (nametableRow = 0; nametableRow < nametableLength; nametableRow++)
	{
		if ((grib_par	== pgrib_par[nametableRow]) &&
			(grib_typ	== pgrib_typ[nametableRow]) &&
			(grib_lev	== pgrib_lev[nametableRow]))
			break;
	}

	if (nametableRow < nametableLength)
		/* Get name, long_name & units */
	{
        outResult = true;

        /* name */
		pTmpMxArray = mxGetCell((const mxArray*)pNametable, 3);
		pTmpMxArray = mxGetCell((const mxArray*)pTmpMxArray, nametableRow);
		mxSetField(plhs[0], index, FIELD_VARNAME, mxDuplicateArray(pTmpMxArray));

		/* long_name */
		pTmpMxArray = mxGetCell((const mxArray*)pNametable, 4);
		pTmpMxArray = mxGetCell((const mxArray*)pTmpMxArray, nametableRow);
		mxSetField(plhs[0], index, FIELD_LONG_NAME, mxDuplicateArray(pTmpMxArray));

		/* units */
		pTmpMxArray = mxGetCell((const mxArray*)pNametable, 5);
		pTmpMxArray = mxGetCell((const mxArray*)pTmpMxArray, nametableRow);
		mxSetField(plhs[0], index, FIELD_UNITS, mxDuplicateArray(pTmpMxArray));

    }
	else
	{
        outResult = false;
		getInfoFromFile(vlistID, varID, plhs, index);

		/* to replace with mxgetstring */
        /* Get the Varname */
		sprintf(buf, "Variable [%d %d %d]  not found in the nametable.", grib_par, grib_typ, grib_lev);
		mexWarnMsgTxt(buf);
	}

    return outResult;
}

/* =============================================================
read the metadata
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	streamID: CDI stream ID of the file to read
	index: index of the MATLAB structure to update
	pGribCode: MATLAB matrix of the grib code [grib_par grib_typ grib_lev]
	pTime: MATLAB array of the timesteps to read or NULL
OUPUT
	plhs: updated MATLAB structure
RETURN
==============================================================*/
void readmeta(int vlistID, int varID, int streamID, mxArray *plhs[], int index, const mxArray *pGribCode, const mxArray *pTime )
{
    mxArray *pTmpMxArray;
    int gridID, tsID, xsize, ysize, nrecs, taxisID;
    double vdate, vtime, hour, minute;
    int T;
    double *pData;

    gridID  = vlistInqVarGrid(vlistID, varID);
    DEBUG_DISPLAY("gridInqType = %d\n",gridInqType(gridID));
    DEBUG_DISPLAY("gridInqSize = %d\n",gridInqSize(gridID));

    xsize    = gridInqXsize(gridID);
    DEBUG_DISPLAY("xsize = %d\n",xsize);
    ysize    = gridInqYsize(gridID);
    DEBUG_DISPLAY("ysize = %d\n",ysize);

    /*-------------------------------------------------------------------*/
    /* LONGITUDE */
    if (gridInqType(gridID)!=9 && gridInqType(gridID)!=10)
       pTmpMxArray = mxCreateDoubleMatrix(1, xsize, mxREAL);
    else
       pTmpMxArray = mxCreateDoubleMatrix(1, gridInqSize(gridID), mxREAL);
    if (gridInqXvals(gridID, (double *)mxGetData(pTmpMxArray)) == 0)
        mxErrMsgIdAndTxt("cdi_library:gridInqXvals", "Function failed.");
    mxSetField(plhs[0], index, FIELD_LON, pTmpMxArray);
    /*-------------------------------------------------------------------*/
    /* LATITUDE */
    if (gridInqType(gridID)!=9 && gridInqType(gridID)!=10)
        pTmpMxArray = mxCreateDoubleMatrix(1, ysize, mxREAL);
    else
        pTmpMxArray = mxCreateDoubleMatrix(1, gridInqSize(gridID), mxREAL);
    if (gridInqYvals(gridID, (double *)mxGetData(pTmpMxArray)) == 0)
        mxErrMsgIdAndTxt("cdi_library:gridInqYvals", "Function failed.");
    mxSetField(plhs[0], index, FIELD_LAT, pTmpMxArray);
    /*-------------------------------------------------------------------*/
    /* NORTHPOLE */
    if ( gridIsRotated(gridID) )
    {
        DEBUG_DISPLAY("northpole : lon = %.9g  lat = %.9g\n", gridInqXpole(gridID), gridInqYpole(gridID));
        pTmpMxArray = mxCreateDoubleScalar(gridInqXpole(gridID));
        mxSetField(plhs[0], index, FIELD_NORTHPOLE_LON, pTmpMxArray);
        pTmpMxArray = mxCreateDoubleScalar(gridInqYpole(gridID));
        mxSetField(plhs[0], index, FIELD_NORTHPOLE_LAT, pTmpMxArray);
    }
    else
    {
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_NORTHPOLE_LON));
        mxRemoveField(plhs[0], mxGetFieldNumber(plhs[0], FIELD_NORTHPOLE_LAT));
    }

    /*-------------------------------------------------------------------*/
    /* DATES */
    if (NULL == pTime)
    {
        getTimeSize(NULL, streamID, &T );
        pTmpMxArray = mxCreateDoubleMatrix(1, T, mxREAL);
        mxSetField(plhs[0], index, FIELD_DATES, pTmpMxArray);
        pData = (double *)mxGetData(pTmpMxArray);
        tsID = 0;
        taxisID = vlistInqTaxis(vlistID);
        while ((nrecs = streamInqTimestep(streamID, tsID)) > 0)
        {
            *pData = getTime(taxisID);
            DEBUG_DISPLAY("Time = %g\n", *pData);
            pData++;
            tsID++;
        }
    }
    else
    {
        mxSetField(plhs[0], index, FIELD_DATES, mxDuplicateArray(pTime));
    }

    /*-------------------------------------------------------------------*/
    /* LEVELS */
    readLevels(streamID, vlistID, varID, plhs, index, pGribCode);

}

/* =============================================================
return the time
INPUT
	taxisID: CDI Time axis ID
OUPUT
RETURN
	date in YYYYMMDD,h format here h is a fraction in 24 hour day
==============================================================*/
double getTime(int taxisID)
{
    double date, hour, minute;
    int time;
    date = (double)taxisInqVdate(taxisID);
    time = taxisInqVtime(taxisID);
    hour   =  (double)(time / 100);
    minute =  (double)time - hour*100;
    return date + (hour + minute/60)/24;
}

/* =============================================================
read the levels
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	streamID: CDI stream ID of the file to read
	index: index of the MATLAB structure to update
	pGribCode: MATLAB matrix of the grib code [grib_par grib_typ grib_lev]
OUPUT
	plhs: updated MATLAB structure
RETURN
==============================================================*/
void readLevels(int streamID, int vlistID, int varID, mxArray *plhs[], int index, const mxArray *pGribCode)
{
    int levelsize, levelID;
    mxArray *pTmpMxArray;
    double *pData;

    int zaxisID = vlistInqVarZaxis(vlistID, varID);
    DEBUG_DISPLAY("zaxisInqType = %d\n", zaxisInqType(zaxisID));
    DEBUG_DISPLAY("zaxisInqSize = %d\n", zaxisInqSize(zaxisID));

     /*-------------------------------------------------------------------*/
    /* LEVELS */
	if (streamInqFiletype(streamID) == FILETYPE_GRB)
    {
        double *pGRIBdata = (double *)mxGetData(pGribCode);
        levelsize = zaxisInqSize(zaxisID);

        for ( levelID = 0; levelID < levelsize; levelID++)
        {
	        int grib_typ, level1, level2;
            getLevel(zaxisID, levelID, &grib_typ, &level1, &level2);
            if (grib_typ == pGRIBdata[1] && level1 == pGRIBdata[2])
            {
                DEBUG_DISPLAY("grib_lev = %d (#%d/%d)\n", level1, levelID+1, levelsize );
                DEBUG_DISPLAY("grib_typ = %d\nlevels: (%.f, %d)\n",  grib_typ, level1, level2);
                DEBUG_DISPLAY("zaxisInqLevel = %d\n", zaxisInqLevel(zaxisID, levelID));

/* RCA uses GRIB level information differently in a number of cases:
- Level 3006 or 4006 stands for averaged and accumulated values, respectively.
- For GRIB codes 242, 250 and 252 each level is a different variable.
The level value in the resulting MATLAB structure should contain 0 for these variables (they are surface variables!),
while the grib_level attribute should retain the original value from the GRIB file. */
				if ( pGRIBdata[2] == 3006 ||
                    pGRIBdata[2] == 4006 ||
                    pGRIBdata[0] == 242 ||
                    pGRIBdata[0] == 250 ||
                    pGRIBdata[0] == 252 )
				{
					/* SPECIAL CASE */
                    mxSetField(plhs[0], index, FIELD_LEVELS, mxCreateDoubleScalar(0));
				}
				else
				{
					if (level2 == 0) /* only one level */
					{
						mxSetField(plhs[0], index, FIELD_LEVELS, mxCreateDoubleScalar(level1));
					}
					else
					{ /* 2 levels */
						pTmpMxArray = mxCreateDoubleMatrix(1, 2, mxREAL);
						mxSetField(plhs[0], index, FIELD_LEVELS, pTmpMxArray);
						pData = (double *)mxGetData(pTmpMxArray);
						*pData = (double)level1;
						*(pData+1) = (double)level2;
					}
				}
				break;
            }
        }
    }
    else
    {
        levelsize = zaxisInqSize(zaxisID);
        pTmpMxArray = mxCreateDoubleMatrix(1, levelsize, mxREAL);
        mxSetField(plhs[0], index, FIELD_LEVELS, pTmpMxArray);
        pData = (double *)mxGetData(pTmpMxArray);

        DEBUG_DISPLAY("levelsize = %d\n", levelsize);
        for ( levelID = 0; levelID < levelsize; levelID++)
        {
            int longLevelType, level1, level2;
            getLevel(zaxisID, levelID, &longLevelType, &level1, &level2);
            *(pData++) = (double)level1;
            DEBUG_DISPLAY("grib_lev = %d (#%d/%d)\n", level1, levelID+1, levelsize );
            DEBUG_DISPLAY("grib_typ = %d\nlevels: (%g, %g)\n",  longLevelType, level1, level2);
            DEBUG_DISPLAY("zaxisInqLevel = %d\n", zaxisInqLevel(zaxisID, levelID));
            DEBUG_DISPLAY("-------------------\n");
        }
    }

	/* check that FIELD_LEVELS is not empty */
	pTmpMxArray = mxGetField(plhs[0], index, FIELD_LEVELS);
	if (mxGetField(plhs[0], index, FIELD_LEVELS) != NULL)
		if (!mxIsEmpty(mxGetField(plhs[0], index, FIELD_LEVELS)))
			return;
	mxSetField(plhs[0], index, FIELD_LEVELS, mxCreateDoubleScalar(1));
}

/* =============================================================
return the number of timesteps
INPUT
	pTime: MATLAB array of the timesteps to read or NULL
	streamID: CDI stream ID of the file to read
OUPUT
	T: number of timesteps
RETURN
==============================================================*/
void getTimeSize(const mxArray *pTime, int streamID, int *T )
{
    int nrecs = 0;
    int tsID;

    /* ==================================================================*/
    /* CHECKING TIMESTEPS
    /* ==================================================================*/
    if (pTime != NULL) /* several time step input */
    {
        *T = (int)mxGetNumberOfElements(pTime);
    }
    else  /* no specified time step => all time steps are read */
    {
        /* Inquire the time steps */
        tsID = 0;
        *T = 0;
        while ( (nrecs = streamInqTimestep(streamID, tsID))> 0)
        {
            *T = (*T) + 1;
            tsID++;
        }
    }
}

/* =============================================================
return the size of a data
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	streamID: CDI stream ID of the file to read
	useGRIB: true if GRIB file, else false
OUPUT
	X: number of x values
	Y: number of y values
	Z: number of z values
RETURN
==============================================================*/
void getSize(int vlistID, int varID, int streamID, bool useGRIB, int *X, int *Y, int *Z )
{
    /* ==================================================================*/
    /* ALLOCATING OUTPUT
    /* ==================================================================*/
	/* Get variable grid ID */
	int gridID = vlistInqVarGrid(vlistID, varID);

	/* Get grid size */
	*X = gridInqXsize(gridID);
	*Y = gridInqYsize(gridID);

	/* Get nof zaxis levels */
    if (useGRIB) /* GRIB variable => 1 level specified */
    {
        *Z = 1;
    }
	else
    {
        /* get zid */
        int zaxisID = vlistInqVarZaxis(vlistID, varID);
    	*Z = zaxisInqSize(zaxisID); /* NetCDF => all levels read */
    }
}

/* =============================================================
read a variable (for a specific timestep)
INPUT
	vlistID: CDI variables list ID
	varID: CDI variable ID
	streamID: CDI stream ID of the file to read
	useGRIB: true if GRIB file, else false
	pVarname: MATLAB input of the variable name
	dims: array of dimension
	tsID: CDI timestep ID
OUPUT
	plhs: updated MATLAB structure
RETURN
==============================================================*/
void readVar(bool useGRIB, int streamID, int vlistID, int varID, mxArray *plhs[], const mxArray *pVarname, mwSize dims[], int tsID)
{
    int nmiss;
    double *pGRIBdata = mxGetData(pVarname);
	unsigned char *pVar = (unsigned char *)mxGetPr(plhs[0]);
    pVar += dims[0]*dims[1]*dims[2]*tsID*mxGetElementSize(plhs[0]);

	DEBUG_DISPLAY("Reading %d (%dx%dx%d)\n",varID, dims[0], dims[1], dims[2]);
    if (useGRIB)
    {
        int zaxisID;
        int levelsize = 0;
        int levelID = 0;

        zaxisID = vlistInqVarZaxis(vlistID, varID);
        levelsize = zaxisInqSize(zaxisID);

        DEBUG_DISPLAY("Searching [%g, %g, %g]\n", pGRIBdata[0], pGRIBdata[1], pGRIBdata[2]);
        for ( levelID = 0; levelID < levelsize; levelID++)
        {
            int grib_typ, grib_lev, level2;
            getLevel(zaxisID, levelID, &grib_typ, &grib_lev, &level2);
            if (grib_typ == pGRIBdata[1] && grib_lev == pGRIBdata[2])
            {
                DEBUG_DISPLAY("Finding [%g, %d, %d], varID = %d\n", pGRIBdata[0], grib_typ, grib_lev, varID);
                if (mxIsDouble(plhs[0]))
                {
                    streamReadVarSlice(streamID, varID, levelID, (double *)pVar, &nmiss);
                }
                else
                {
                    mxArray *tempDoubleArray[1];
                    size_t bytes_to_copy;
                    tempDoubleArray[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
                    streamReadVarSlice(streamID, varID, levelID, (double *)mxGetPr(tempDoubleArray[0]), &nmiss);
                    CONVERSION(tempDoubleArray);
                    bytes_to_copy = ((size_t)(dims[0]*dims[1]*dims[2]))*mxGetElementSize(plhs[0]);
                    DEBUG_DISPLAY("Copying %d bytes\n", bytes_to_copy);
                    memcpy((unsigned char *)pVar, (unsigned char *)mxGetPr(tempDoubleArray[0]), bytes_to_copy);
                    mxDestroyArray(tempDoubleArray[0]);
                }
            }
        }
    }
    /* --------------------------------------------------------------------------*/
    else /* useGRIB */
    {
        if (mxIsDouble(plhs[0]))
        {
            streamReadVar(streamID, varID, (double *)pVar, &nmiss);
        }
        else
        {
            mxArray *tempDoubleArray[1];
            size_t bytes_to_copy;
            tempDoubleArray[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
            streamReadVar(streamID, varID, (double *)mxGetPr(tempDoubleArray[0]), &nmiss);
            CONVERSION(tempDoubleArray);
            bytes_to_copy = ((size_t)(dims[0]*dims[1]*dims[2]))*mxGetElementSize(plhs[0]);
            DEBUG_DISPLAY("Copying %d bytes\n", bytes_to_copy);
            memcpy((unsigned char *)pVar, (unsigned char *)mxGetPr(tempDoubleArray[0]), bytes_to_copy);
            mxDestroyArray(tempDoubleArray[0]);
        }
    }
}

/* =============================================================
returns the number of different variable in a file
INPUT
	streamID: CDI stream ID of the file to read
OUPUT
RETURN
	number of variables in the file
==============================================================*/
int getNumberOfVariables(int streamID)
{
    int outResult = 0;
	/* Get the variable list of the dataset */
	int vlistID = streamInqVlist(streamID);
	/* get number of variables */
    int nVars = vlistNvars(vlistID);

    if (streamInqFiletype(streamID) == FILETYPE_GRB) /* GRIB files: 1 variable/per level */
    {
        int varID;
        for (varID = 0; varID < nVars; varID++)
        {
            int zaxisID = vlistInqVarZaxis(vlistID, varID);
            outResult += zaxisInqSize(zaxisID); /* levelsize */
		}
    }
    else
    {
        outResult = nVars;
    }
    return outResult;
}


/* =============================================================
checks the input variable ID
INPUT
	input: MATLAB variable identifier (name or grib code)
OUPUT
	useGRIB: true if GRIB file, else false
	pVarname: MATLAB variable identifier (name or grib code)
RETURN
==============================================================*/
void checkInputVarname(mxArray **pVarname, bool *useGRIB, mxArray *input)
{
	if (mxIsChar(input))
    {
        *useGRIB = false;
		*pVarname = input;
    }
	else if (mxIsNumeric(input))
    {
        *useGRIB = true;
		*pVarname = input;
    }
	else
		mexErrMsgTxt("Input 3 must a string (varname) or a matrix ([grib_par, grib_typ, grib_lev]) for GRIB files.");
}

/* =============================================================
read all the values for one variable
INPUT
	pTime: MATLAB array of timesteps or NULL
	useGRIB: true if GRIB file, else false
	streamID: CDI stream ID of the file to read
	vlistID: CDI variables list ID
	varID: CDI variable ID
	pVarname: MATLAB variable identifier
	dims: array of dimensions
OUPUT
	plhs: MATLAB matrix
RETURN
==============================================================*/
void readField(const mxArray *pTime, bool useGRIB, int streamID, int vlistID, int varID, mxArray *plhs[], const mxArray *pVarname, mwSize dims[])
{
    int taxisID;
    int tsID = 0;
    double *pTimeData = NULL;
    size_t timeToReadNb = 0;
    size_t timeIndex = 0;
    double time;
	char buf[MEXCDI_STR_LEN];

    if (mxIsEmpty(plhs[0]))
        return;

    if (pTime != NULL)
    {
        pTimeData = mxGetPr(pTime);
        timeToReadNb = mxGetNumberOfElements(pTime);
    }

    taxisID = vlistInqTaxis(vlistID);

    DEBUG_DISPLAY("Reading %d\n",varID);
    while (streamInqTimestep(streamID, tsID) > 0)
	{
        DEBUG_DISPLAY("Time = %d\n",tsID);
        if (pTime == NULL) /* all time steps required */
        {
            readVar(useGRIB, streamID, vlistID, varID, plhs, pVarname, dims, tsID);
            /* go to next timestep */
            tsID++;
        }
        else /* specified time step input */
        {
            time = getTime(taxisID);
            if (time == *pTimeData)
            {
                readVar(useGRIB, streamID, vlistID, varID, plhs, pVarname, dims, timeIndex);
                /* go the the next specified time input */
                pTimeData++;
                timeIndex++;
                /* go to next timestep */
                tsID++;
            }
            else if (time > *pTimeData)
            {
                /* offset between input time and read time */
                /* move to the next input time */
                sprintf(buf, "Time %.4f not found in the data file.", *pTimeData);
                mexWarnMsgTxt(buf);

                pTimeData++;
                timeIndex++;
            }
            else
            {
                /* offset between input time and read time */
                /* move to the next timestep */
                tsID++;
            }
           /* we have all the time we want => exit */
            if (timeIndex == timeToReadNb)
                break;
        }
	}
}

/* =============================================================
allocates the memory for all the values of a variable
INPUT
	useGRIB: true if GRIB file, else false
	streamID: CDI stream ID of the file to read
	vlistID: CDI variables list ID
	varID: CDI variable ID
	dims: array of dimensions
	T: number of timesteps
OUPUT
	plhs: MATLAB matrix
RETURN
==============================================================*/
bool allocateField(bool useGRIB, int vlistID, int varID, int streamID, int T, mwSize dims[4], mxArray *plhs[])
{
    int X, Y, Z;
    bool outIsEmpty = false;
    int i;

    DEBUG_DISPLAY("varID = %d\n", varID);
	getSize(vlistID, varID, streamID, useGRIB, &X, &Y, &Z );
    dims[0] = X;
    dims[1] = Y;
    dims[2] = Z;
    dims[3] = T;
    DEBUG_DISPLAY("X,Y,Z,T = %d;%d;%d;%d\n", X, Y, Z, T);
    if (X == 0 || Y == 0 || Z == 0 || T == 0)
    {
        plhs[0] = mxCreateNumericArray(0, 0, ML_CDI_TYPE, mxREAL);
        outIsEmpty = true;
    }
    else
    {
        mxArray *arrayDim[4];
        arrayDim[0] = mxCreateDoubleScalar(X);
        arrayDim[1] = mxCreateDoubleScalar(Y);
        arrayDim[2] = mxCreateDoubleScalar(Z);
        arrayDim[3] = mxCreateDoubleScalar(T);

        /* it will raise an error "Out of memory" if not enough memory */
        if (0 != mexCallMATLAB(1, &plhs[0], 4, arrayDim, "nan"))
        {
            char buf[MEXCDI_STR_LEN];
            sprintf(buf, "mexCallMATLAB failed with \"nan\".");
            mexErrMsgTxt(buf);
        }
        for (i = 0; i < 4; i++)
            mxDestroyArray(arrayDim[i]);

        CONVERSION(plhs);

        outIsEmpty = false;
    }
    return outIsEmpty;
}
