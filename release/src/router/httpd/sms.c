/*
	Tomato Firmware
	Portions, Copyright (C) 2014 Philip Bordado
*/

#include "tomato.h"

void wo_sms(char *url)
{
	//char cmd[256];
	FILE *fp;
	const char *read, *number, *message, *delete;
	char s[100];
	char d[16];

	read = webcgi_get("read");
	delete = webcgi_get("delete");
	number = webcgi_get("number");
	message = webcgi_get("message");

	killall("comgt", SIGTERM);
	sprintf(&d[0], "/dev/%s", nvram_safe_get("sms_dev"));

	// send sms	
	if (number && message) {
		if ((fp = fopen("/tmp/sms.gcom", "w")) != NULL) {
			fprintf(fp,
				"opengt\n"
				"set com 115200n81\n"
				"set senddelay 0.05\n"
				"waitquiet 0.2 0.2\n"
				"send \"AT+CMGF=1^m\"\n"
				"gosub wait_ok\n"
				"send \"AT+CMGS=\\\"%s\\\"^m%s^z\"\n"
				"let i=0\n"
				":get_next\n"
				"get 1 \"^m\" $s\n"
				"print $s\n"
				"let $a=$s\n"
				"if len($a)>=3 let $b=$right($a,2)\n"
				"if $b=\"OK\" goto exit\n"
				"inc i\n"
				"if i<45 goto get_next\n"
				":exit\n"
				"print \"\\n\"\n"
				"exit 0\n"
				":wait_ok\n"
				"let t=0\n"
				":get_again\n"
				"get 1 \" ^m\" $s\n"
				"let $a=$s\n"
				"if len($a)>=3 let $b=$right($a,2)\n"
				"if $b=\"OK\" goto got_ok\n"
				"else inc t\n"
				"if t<45 goto get_again\n"
				"else goto return\n"
				":got_ok\n"
				":return\n"
				"return\n",
				number,
				message);
			fclose(fp);
			// cmd
			eval("comgt", "-d", &d[0], "-s", "/tmp/sms.gcom");
		}
	}
	
	// delete sms	
	if (delete) {
		if ((fp = fopen("/tmp/sms.gcom", "w")) != NULL) {
			fprintf(fp,
				"opengt\n"
				"set com 115200n81\n"
				"set senddelay 0.05\n"
				"waitquiet 0.2 0.2\n"
				"send \"AT+CMGD=%s^m\"\n"
				"let i=0\n"
				":get_next\n"
				"get 1 \"^m\" $s\n"
				"print $s\n"
				"let $a=$s\n"
				"if len($a)>=3 let $b=$right($a,2)\n"
				"if $b=\"OK\" goto exit\n"
				"inc i\n"
				"if i<45 goto get_next\n"
				":exit\n"
				"print \"\\n\"\n"
				"exit 0\n",
				delete);
			fclose(fp);
			// cmd
			eval("comgt", "-d", &d[0], "-s", "/tmp/sms.gcom");
		}
	}

	// read sms	
	if (read) {
		if ((fp = fopen("/tmp/sms.gcom", "w")) != NULL) {
			fprintf(fp,
				"opengt\n"
				"set com 115200n81\n"
				"set senddelay 0.02\n"
				"waitquiet 0.2 0.2\n"
				"send \"AT+CMGF=0^m\"\n"
				"gosub wait_ok\n"
				"send \"AT+CSMP=17,167^m\"\n"
				"gosub wait_ok\n"
				"send \"AT+CPMS=\\\"SM\\\",\\\"SM\\\",\\\"SM\\\"^m\"\n"
				"gosub wait_ok\n"
				"send \"AT+CMGL=4^m\"\n"
				"let i=0\n"
				":get_next\n"
				"get 1 \"^m\" $s\n"
				"print $s\n"
				"let $a=$s\n"
				"if len($a)>=3 let $b=$right($a,2)\n"
				"if $b=\"OK\" goto exit\n"
				"inc i\n"
				"if i<45 goto get_next\n"
				":exit\n"
				"print \"\\n\"\n"
				"exit 0\n"
				":wait_ok\n"
				"let t=0\n"
				":get_again\n"
				"get 1 \" ^m\" $s\n"
				"let $a=$s\n"
				"if len($a)>=3 let $b=$right($a,2)\n"
				"if $b=\"OK\" goto got_ok\n"
				"else inc t\n"
				"if t<45 goto get_again\n"
				"else goto return\n"
				":got_ok\n"
				":return\n"
				"return\n");
			fclose(fp);
			// cmd
			web_puts("\nsmsdata = '");
			sprintf(&s[0], "comgt -d /dev/%s -s /tmp/sms.gcom", nvram_safe_get("sms_dev"));
			web_pipecmd(&s[0], WOF_JAVASCRIPT);
			web_puts("';");
		}
	}
}

