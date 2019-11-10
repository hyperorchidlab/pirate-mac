#ifndef _CALL_BACK_HEADER_
#define _CALL_BACK_HEADER_

        typedef void (*UserInterfaceAPI) (int, int, char*);
        void bridge_func(UserInterfaceAPI f , int t, int t2, char* v);

        enum CallBackActionType{
            ExitByErr,
            Log,
            Notification,
        };

#endif