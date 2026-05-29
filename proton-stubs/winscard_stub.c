#include <windows.h>
#include <winscard.h>

LONG WINAPI SCardEstablishContext(DWORD scope, LPCVOID reserved1, LPCVOID reserved2, LPSCARDCONTEXT context)
{
    if (context) *context = 1;
    return SCARD_S_SUCCESS;
}

LONG WINAPI SCardReleaseContext(SCARDCONTEXT context)
{
    return SCARD_S_SUCCESS;
}

LONG WINAPI SCardFreeMemory(SCARDCONTEXT context, LPCVOID memory)
{
    return SCARD_S_SUCCESS;
}

LONG WINAPI SCardListReadersW(SCARDCONTEXT context, LPCWSTR groups, LPWSTR readers, LPDWORD readers_len)
{
    if (readers_len) *readers_len = 0;
    return SCARD_E_NO_READERS_AVAILABLE;
}

LONG WINAPI SCardListCardsW(SCARDCONTEXT context, LPCBYTE atr, LPCGUID interfaces, DWORD interface_count, LPWSTR cards, LPDWORD cards_len)
{
    if (cards_len) *cards_len = 0;
    return SCARD_E_NO_SMARTCARD;
}

LONG WINAPI SCardGetStatusChangeW(SCARDCONTEXT context, DWORD timeout, LPSCARD_READERSTATEW states, DWORD readers)
{
    return SCARD_E_TIMEOUT;
}

LONG WINAPI SCardGetCardTypeProviderNameW(SCARDCONTEXT context, LPCWSTR card_name, DWORD provider_id, LPWSTR provider, LPDWORD provider_len)
{
    if (provider_len) *provider_len = 0;
    return SCARD_E_UNKNOWN_CARD;
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved)
{
    return TRUE;
}
