/*
	Tomato Firmware
	Copyright (C) 2014 Philip Bordado
*/

#include "rc.h"

void start_ppp3g(void)
{
	TRACE_PT("begin\n");

	FILE *f;
	FILE *fp;

	int ppp3g_en = nvram_get_int("ppp3g_en");

	mkdir("/tmp/ppp", 0777);
	mkdir("/tmp/ppp/peers", 0777);

	if (ppp3g_en) {

		if ((fp = fopen("/tmp/ppp/peers/ppp3g", "w")) != NULL) {
			fprintf(fp,
				"/dev/%s\n"
				"nodetach\n"
				"crtscts\n"
				"noauth\n"
				"connect \"/usr/sbin/chat -v -f /tmp/ppp/peers/ppp3g-chat\"\n"
				"nodefaultroute\n"
				"noipdefault\n"
				"novj\n",
				nvram_safe_get("ppp3g_dev"));
			if (strlen(nvram_get("ppp3g_username")) >0 ) {
				fprintf(fp, "user '%s'\n", nvram_get("ppp3g_username"));
				if ((f = fopen("/tmp/ppp/pap-secrets", "w")) != NULL) {
					fprintf(f, "\"%s\" * \"%s\" *\n",
						nvram_safe_get("ppp3g_username"),
						nvram_safe_get("ppp3g_passwd"));
					fclose(f);
					chmod("/tmp/ppp/pap-secrets", 0600);
				}

				if ((f = fopen("/tmp/ppp/chap-secrets", "w")) != NULL) {
					fprintf(f, "\"%s\" * \"%s\" *\n",
						nvram_safe_get("ppp3g_username"),
						nvram_safe_get("ppp3g_passwd"));
					fclose(f);
					chmod("/tmp/ppp/chap-secrets", 0600);
				}
			}
			// User specific options
			fprintf(fp, "%s\n", nvram_safe_get("ppp3g_custom"));
			fclose(fp);
		}

		if ((fp = fopen("/tmp/ppp/peers/ppp3g-chat", "w")) != NULL) {
			fprintf(fp,
				"ABORT BUSY\n"
				"ABORT \"NO CARRIER\"\n"
				"ABORT ERROR\n"
				"REPORT CONNECT\n"
				"TIMEOUT 10\n"
				"\"\" \"AT&F\"\n"
				"OK \"ATE1\"\n"
				"OK 'AT+CGDCONT=1,\"IP\",\"%s\"'\n"
				"TIMEOUT 60\n"
				"OK \"ATD%s\"\n"
				"CONNECT \\c\n",
				nvram_safe_get("ppp3g_apn"),
				nvram_safe_get("ppp3g_init"));
			fclose(fp);
		}

		// detect 3G Modem
		eval("switch3g");

		// create ip-up script
		if ((f = fopen("/tmp/ppp/ip-up", "w")) != NULL) {
			fprintf(f,
				"#!/bin/sh\n"
				"iptables -t nat -A POSTROUTING -j MASQUERADE -o $1\n"
				"%s\n",
				nvram_safe_get("ppp3g_ipup"));
			fclose(f);
			chmod("/tmp/ppp/ip-up", 0755);
		}

		// create ip-down script
		if ((f = fopen("/tmp/ppp/ip-down", "w")) != NULL) {
			fprintf(f,
				"#!/bin/sh\n"
				"iptables -t nat -D POSTROUTING -j MASQUERADE -o $1\n"
				"%s\n",
				nvram_safe_get("ppp3g_ipdown"));
			fclose(f);
			chmod("/tmp/ppp/ip-down", 0755);
		}

		if (nvram_get_int("ppp3g_demand")) {
			// on demand / single fire
			xstart("pppd", "call", "ppp3g");
		}
		else {
			// keepalive mode
			if ((f = fopen("/tmp/ppp/ppp3g_redial.sh", "w")) != NULL) {
				fprintf(f,
					"#!/bin/sh\n"
					"while [ 1 ]\n"
					"do\n"
					"	pppd call ppp3g\n"
					"	sleep %s\n"
					"done\n",
					nvram_safe_get("ppp3g_redialperiod"));
				fclose(f);
				chmod("/tmp/ppp/ppp3g_redial.sh", 0755);
				xstart("/tmp/ppp/ppp3g_redial.sh");
			}
		}

	}

	TRACE_PT("end\n");
	return 0;
}

void stop_ppp3g(void)
{
	TRACE_PT("begin\n");

	killall_tk("ppp3g_redial.sh");
	killall_tk("pppd");

	TRACE_PT("end\n");
}


