#include <windows.h>
#include <stdio.h>

typedef GUID SLID;
typedef void *HSLC;
typedef void *HSLP;

typedef enum
{
    SL_DATA_NONE     = REG_NONE,
    SL_DATA_SZ       = REG_SZ,
    SL_DATA_DWORD    = REG_DWORD,
    SL_DATA_BINARY   = REG_BINARY,
    SL_DATA_MULTI_SZ = REG_MULTI_SZ,
} SLDATATYPE;

typedef struct
{
    SLID SkuId;
    DWORD eStatus;
    DWORD dwGraceTime;
    DWORD dwTotalGraceDays;
    HRESULT hrReason;
    ULONGLONG qwValidityExpiration;
} SL_LICENSING_STATUS;

typedef HRESULT (WINAPI *SLOpenFunc)(HSLC *handle);
typedef HRESULT (WINAPI *SLCloseFunc)(HSLC handle);
typedef HRESULT (WINAPI *SLConsumeRightFunc)(HSLC handle, const SLID *app, const SLID *product,
                                             const WCHAR *right_name, void *reserved);
typedef HRESULT (WINAPI *SLSetAuthenticationDataFunc)(HSLC handle, UINT size, const BYTE *data);
typedef HRESULT (WINAPI *SLGetAuthenticationResultFunc)(HSLC handle, UINT *size, BYTE **data);
typedef HRESULT (WINAPI *SLGetPolicyInformationFunc)(HSLC handle, const WCHAR *name, SLDATATYPE *type,
                                                     UINT *size, BYTE **data);
typedef HRESULT (WINAPI *SLLoadApplicationPoliciesFunc)(const SLID *app, const SLID *product,
                                                        DWORD flags, HSLP *context);
typedef HRESULT (WINAPI *SLGetApplicationPolicyFunc)(HSLP context, const WCHAR *name, SLDATATYPE *type,
                                                     UINT *size, BYTE **data);
typedef HRESULT (WINAPI *SLUnloadApplicationPoliciesFunc)(HSLP context, DWORD flags);
typedef HRESULT (WINAPI *SLGetLicensingStatusInformationFunc)(HSLC handle, const SLID *app,
                                                              const SLID *product, const WCHAR *name,
                                                              UINT *count, SL_LICENSING_STATUS **status);
typedef HRESULT (WINAPI *SLGetProductSkuInformationFunc)(HSLC handle, const SLID *product,
                                                         const WCHAR *name, SLDATATYPE *type,
                                                         UINT *size, BYTE **data);

static const SLID excel_app = {0x0ff1ce15,0xa989,0x479d,{0xaf,0x46,0xf2,0x75,0xc6,0x37,0x06,0x63}};

static const BYTE excel_auth_challenge[] =
{
    0x20,0x01,0x00,0x00,0x01,0x00,0x00,0x00,0x00,0x00,0x01,0x00,0x0c,0x01,0x00,0x00,
    0x01,0x02,0x00,0x00,0x10,0x66,0x00,0x00,0x00,0xa4,0x00,0x00,0x08,0x31,0xea,0xe6,
    0xe3,0xfd,0x70,0x05,0x4e,0xc7,0x07,0x25,0x01,0x62,0x24,0xc4,0x66,0x91,0x3a,0x84,
    0x49,0x47,0xb8,0x4c,0xc6,0x43,0x0b,0x0d,0xf5,0x84,0x95,0xa0,0xbc,0x1d,0x2c,0xbc,
    0x8c,0x04,0x0c,0x1f,0x64,0x09,0x1b,0x11,0x06,0xdb,0x58,0xfe,0x18,0x5b,0x41,0x38,
    0x0d,0x6e,0x16,0x7e,0xba,0xab,0xf1,0x5f,0xee,0x2b,0x7b,0x76,0xea,0x88,0xfd,0xae,
    0xc4,0xbf,0xba,0x21,0xeb,0xb8,0x60,0x6d,0x1f,0xf3,0x53,0x67,0x3b,0x93,0xff,0xb2,
    0xc5,0x92,0x73,0x79,0xb3,0x79,0x1d,0x80,0x55,0xcf,0x5d,0x9b,0xfd,0xd9,0x93,0x58,
    0x3d,0x51,0x81,0xf6,0xd7,0xf5,0xe8,0x74,0x77,0x5e,0xfe,0xb3,0x6b,0x4a,0xa1,0x15,
    0xc6,0x39,0x8b,0xb3,0x8a,0x33,0xad,0x58,0xc5,0x9a,0xee,0xc1,0x77,0x62,0x1a,0xf1,
    0xf4,0xe6,0x86,0x52,0xfc,0xa9,0x20,0x89,0xcd,0x7a,0x46,0x58,0x02,0x16,0x3c,0xc8,
    0xee,0xc9,0x33,0x45,0x21,0xf2,0x04,0x38,0x5a,0xcc,0x41,0x46,0xbf,0x44,0xf9,0xa3,
    0xbc,0xbe,0x35,0x94,0x3e,0x49,0xd2,0x18,0xf6,0x88,0x8d,0x26,0xcf,0xfc,0x5e,0x15,
    0x28,0x8a,0x1c,0xb7,0xf1,0x64,0xde,0xc0,0xd8,0xc4,0x48,0x40,0xfc,0x0d,0x27,0x2c,
    0xae,0x96,0x7f,0xb7,0x80,0xe5,0x42,0x87,0xdf,0xe3,0xd0,0xab,0x30,0x6a,0xbd,0x55,
    0x5c,0x9c,0x56,0xdf,0x3f,0x8b,0xec,0x33,0xb2,0x54,0x63,0x94,0x65,0x29,0x08,0x0d,
    0x4a,0x15,0x55,0x2a,0x26,0xf3,0xf1,0x00,0x68,0xec,0x98,0xae,0xe0,0xa1,0x42,0xe2,
    0x0e,0x0d,0x6f,0xac,0x91,0x08,0xd8,0x5f,0xc2,0xc9,0x25,0x86,0x55,0x00,0x41,0x00
};

static unsigned int checksum(const BYTE *data, UINT size)
{
    unsigned int hash = 2166136261u;
    UINT i;

    for (i = 0; i < size; ++i)
        hash = (hash ^ data[i]) * 16777619u;
    return hash;
}

static void print_value(const char *label, HRESULT hr, SLDATATYPE type, UINT size, BYTE *data)
{
    printf("%s hr=0x%08lx type=%u size=%u", label, (unsigned long)hr, (unsigned int)type, size);
    if (SUCCEEDED(hr) && data)
    {
        if (type == SL_DATA_DWORD && size >= sizeof(DWORD))
            printf(" dword=%lu", (unsigned long)*(DWORD *)data);
        else if ((type == SL_DATA_SZ || type == SL_DATA_MULTI_SZ) && size >= sizeof(WCHAR))
            printf(" first='%ls'", (WCHAR *)data);
        printf(" hash=0x%08x", checksum(data, size));
    }
    printf("\n");
    if (data) LocalFree(data);
}

static void print_guid(const GUID *guid)
{
    printf("{%08lx-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x}",
           (unsigned long)guid->Data1, guid->Data2, guid->Data3,
           guid->Data4[0], guid->Data4[1], guid->Data4[2], guid->Data4[3],
           guid->Data4[4], guid->Data4[5], guid->Data4[6], guid->Data4[7]);
}

static void query_policy(SLGetPolicyInformationFunc fn, HSLC handle, const WCHAR *name)
{
    SLDATATYPE type = SL_DATA_NONE;
    UINT size = 0;
    BYTE *data = NULL;
    char label[160];
    HRESULT hr;

    snprintf(label, sizeof(label), "SLGetPolicyInformation(%ls)", name);
    hr = fn(handle, name, &type, &size, &data);
    print_value(label, hr, type, size, data);
}

static void query_app_policy(SLGetApplicationPolicyFunc fn, HSLP context, const WCHAR *name)
{
    SLDATATYPE type = SL_DATA_NONE;
    UINT size = 0;
    BYTE *data = NULL;
    char label[160];
    HRESULT hr;

    snprintf(label, sizeof(label), "SLGetApplicationPolicy(%ls)", name);
    hr = fn(context, name, &type, &size, &data);
    print_value(label, hr, type, size, data);
}

int main(void)
{
    HMODULE sppc = LoadLibraryW(L"sppc.dll");
    SLOpenFunc pSLOpen;
    SLCloseFunc pSLClose;
    SLConsumeRightFunc pSLConsumeRight;
    SLSetAuthenticationDataFunc pSLSetAuthenticationData;
    SLGetAuthenticationResultFunc pSLGetAuthenticationResult;
    SLGetPolicyInformationFunc pSLGetPolicyInformation;
    SLLoadApplicationPoliciesFunc pSLLoadApplicationPolicies;
    SLGetApplicationPolicyFunc pSLGetApplicationPolicy;
    SLUnloadApplicationPoliciesFunc pSLUnloadApplicationPolicies;
    SLGetLicensingStatusInformationFunc pSLGetLicensingStatusInformation;
    SLGetProductSkuInformationFunc pSLGetProductSkuInformation;
    HSLC handle = NULL;
    HSLP context = NULL;
    HRESULT hr;
    SLDATATYPE type = SL_DATA_NONE;
    UINT size = 0, count = 0;
    BYTE *data = NULL;
    SL_LICENSING_STATUS *status = NULL;

    if (!sppc)
    {
        printf("LoadLibrary(sppc.dll) failed: %lu\n", GetLastError());
        return 1;
    }

    pSLOpen = (SLOpenFunc)GetProcAddress(sppc, "SLOpen");
    pSLClose = (SLCloseFunc)GetProcAddress(sppc, "SLClose");
    pSLConsumeRight = (SLConsumeRightFunc)GetProcAddress(sppc, "SLConsumeRight");
    pSLSetAuthenticationData = (SLSetAuthenticationDataFunc)GetProcAddress(sppc, "SLSetAuthenticationData");
    pSLGetAuthenticationResult = (SLGetAuthenticationResultFunc)GetProcAddress(sppc, "SLGetAuthenticationResult");
    pSLGetPolicyInformation = (SLGetPolicyInformationFunc)GetProcAddress(sppc, "SLGetPolicyInformation");
    pSLLoadApplicationPolicies = (SLLoadApplicationPoliciesFunc)GetProcAddress(sppc, "SLLoadApplicationPolicies");
    pSLGetApplicationPolicy = (SLGetApplicationPolicyFunc)GetProcAddress(sppc, "SLGetApplicationPolicy");
    pSLUnloadApplicationPolicies = (SLUnloadApplicationPoliciesFunc)GetProcAddress(sppc, "SLUnloadApplicationPolicies");
    pSLGetLicensingStatusInformation = (SLGetLicensingStatusInformationFunc)GetProcAddress(sppc, "SLGetLicensingStatusInformation");
    pSLGetProductSkuInformation = (SLGetProductSkuInformationFunc)GetProcAddress(sppc, "SLGetProductSkuInformation");

    if (!pSLOpen || !pSLClose || !pSLConsumeRight || !pSLSetAuthenticationData ||
        !pSLGetAuthenticationResult || !pSLGetPolicyInformation || !pSLLoadApplicationPolicies ||
        !pSLGetApplicationPolicy || !pSLUnloadApplicationPolicies || !pSLGetLicensingStatusInformation ||
        !pSLGetProductSkuInformation)
    {
        printf("missing sppc exports\n");
        return 2;
    }

    hr = pSLOpen(&handle);
    printf("SLOpen hr=0x%08lx handle=%p\n", (unsigned long)hr, handle);
    if (FAILED(hr)) return 0;

    hr = pSLSetAuthenticationData(handle, sizeof(excel_auth_challenge), excel_auth_challenge);
    printf("SLSetAuthenticationData hr=0x%08lx\n", (unsigned long)hr);

    hr = pSLConsumeRight(handle, &excel_app, NULL, NULL, NULL);
    printf("SLConsumeRight hr=0x%08lx\n", (unsigned long)hr);

    query_policy(pSLGetPolicyInformation, handle, L"*");

    hr = pSLLoadApplicationPolicies(&excel_app, NULL, 0, &context);
    printf("SLLoadApplicationPolicies hr=0x%08lx context=%p\n", (unsigned long)hr, context);
    if (SUCCEEDED(hr))
    {
        query_app_policy(pSLGetApplicationPolicy, context, L"*");
        pSLUnloadApplicationPolicies(context, 0);
    }

    query_policy(pSLGetPolicyInformation, handle, L"office-C845E028-E091-442E-8202-21F596C559A0");
    hr = pSLGetAuthenticationResult(handle, &size, &data);
    print_value("SLGetAuthenticationResult#1", hr, SL_DATA_BINARY, size, data);

    query_policy(pSLGetPolicyInformation, handle, L"office-ParentCode");
    hr = pSLGetAuthenticationResult(handle, &size, &data);
    print_value("SLGetAuthenticationResult#2", hr, SL_DATA_BINARY, size, data);

    hr = pSLGetLicensingStatusInformation(handle, NULL, NULL, NULL, &count, &status);
    printf("SLGetLicensingStatusInformation hr=0x%08lx count=%u", (unsigned long)hr, count);
    if (SUCCEEDED(hr) && status && count)
    {
        unsigned int i;

        printf(" status=%lu grace=%lu reason=0x%08lx", (unsigned long)status[0].eStatus,
               (unsigned long)status[0].dwGraceTime, (unsigned long)status[0].hrReason);
        printf(" first_sku=");
        print_guid(&status[0].SkuId);
        printf("\n");
        for (i = 0; i < count; ++i)
        {
            printf("  licensing_status[%u] sku=", i);
            print_guid(&status[i].SkuId);
            printf(" status=%lu reason=0x%08lx\n", (unsigned long)status[i].eStatus,
                   (unsigned long)status[i].hrReason);
        }
    }
    else
        printf("\n");

    hr = pSLGetProductSkuInformation(handle, &excel_app, L"ApplicationBitmap", &type, &size, &data);
    print_value("SLGetProductSkuInformation(app/ApplicationBitmap)", hr, type, size, data);

    if (status)
    {
        unsigned int i, limit = count < 4 ? count : 4;

        for (i = 0; i < limit; ++i)
        {
            char label[96];

            type = SL_DATA_NONE;
            size = 0;
            data = NULL;
            snprintf(label, sizeof(label), "SLGetProductSkuInformation(status[%u]/ApplicationBitmap)", i);
            hr = pSLGetProductSkuInformation(handle, &status[i].SkuId, L"ApplicationBitmap", &type, &size, &data);
            print_value(label, hr, type, size, data);
        }
        LocalFree(status);
    }

    hr = pSLClose(handle);
    printf("SLClose hr=0x%08lx\n", (unsigned long)hr);
    return 0;
}
