#ifdef __WEAK__
extern int syncfs() __attribute((weak));
#elif __VOID__
extern void syncfs();
#else
extern int syncfs();
#endif

void dummy() {
	syncfs();
}

/*
int main() {
	return syncfs();
}
*/
