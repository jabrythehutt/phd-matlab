/*
* =============================================================
* cdi_mx.h
* This is a header file of a MEX-file for MATLAB to enable the use of the CDI library.
* =============================================================
*/

#include "mex.h"

/* =============================================================
MACRO: CONVERSION
==============================================================*/
#ifdef DOUBLE
#define CONVERSION(x) /* nothing to do: double is the MATLAB native format */
#define ML_CDI_TYPE mxDOUBLE_CLASS
#else
#define CONVERSION(x) conversion(x, "single") /* conversion to single by default */
#define ML_CDI_TYPE mxSINGLE_CLASS
#endif

/* =============================================================
MACRO: DISPLAY INFO FOR DEBUG 
==============================================================*/
#ifdef DEBUG
    #define DEBUG_DISPLAY(...) \
    { \
    	char buf[MEXCDI_STR_LEN];\
        sprintf(buf,__VA_ARGS__);\
        mexPrintf(buf); \
    }
#else
    #define DEBUG_DISPLAY(...); /* do nothing */
#endif

/* =============================================================
special values
==============================================================*/
#define MEXCDI_STR_LEN 512 /* size of the string buffer */

/* =============================================================
field structure names
==============================================================*/
extern const char FIELD_VARID[]; /* INTERNAL USE ONY */
extern const char FIELD_VARCODE[]; /* INTERNAL USE ONY */
extern const char FIELD_VARNAME[];
extern const char FIELD_LONG_NAME[];
extern const char FIELD_UNITS[];
extern const char FIELD_GRIB_PAR[];
extern const char FIELD_GRIB_TYP[];
extern const char FIELD_GRIB_LEV[];
extern const char FIELD_LON[];
extern const char FIELD_LAT[];
extern const char FIELD_NORTHPOLE_LON[];
extern const char FIELD_NORTHPOLE_LAT[];
extern const char FIELD_LEVELS[];
extern const char FIELD_DATES[];
extern const char FIELD_DATA[];

/* =============================================================
functions declarations
==============================================================*/
void conversion(mxArray *inoutMatrix[], char *MATLABConversionFunctionName);
int GetGribTable(const mxArray *mxFilename, mxArray **nametable);
int getVarIDByGRIB(const mxArray *pGRIBcode, int vlistID);
int getVarIDByName(const mxArray *pVarname, int vlistID);
mxArray* getGRIBByName(const mxArray* pVarname, const mxArray *nametable);
int OpenCDIStream(const mxArray *mxFilename);
void getLevel(int zaxisID, int levelID, int *outLongLevelType, int *outLevel1, int *outLevel2);
void getInfoFromFile(int vlistID, int varID, mxArray *plhs[], int index);
bool replaceInfoFromTablename(int vlistID, int varID, int grib_par, int grib_typ, int grib_lev, mxArray *plhs[], int index, const mxArray* pNametable, int nametableLength);
void readmeta(int vlistID, int varID, int streamID, mxArray *plhs[], int index, const mxArray *pGribCode, const mxArray *pTime );
double getTime(int taxisID);
void readLevels(int streamID, int vlistID, int varID, mxArray *plhs[], int index, const mxArray *pGribCode);
void getTimeSize(const mxArray *pTime, int streamID, int *T );
void getSize(int vlistID, int varID, int streamID, bool useGRIB, int *X, int *Y, int *Z );
void readVar(bool useGRIB, int streamID, int vlistID, int varID, mxArray *plhs[], const mxArray *pVarname, mwSize dims[], int tsID);
int getNumberOfVariables(int streamID);
void checkInputVarname(mxArray **pVarname, bool *useGRIB, mxArray *input);
void readField(const mxArray *pTime, bool useGRIB, int streamID, int vlistID, int varID, mxArray *plhs[], const mxArray *pVarname, mwSize dims[]);
bool allocateField(bool useGRIB, int vlistID, int varID, int streamID, int T, mwSize dims[4], mxArray *plhs[]);


