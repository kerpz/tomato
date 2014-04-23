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

	mkdir("/tmp/ppp", 0777);
	mkdir("/tmp/ppp/peers", 0777);
	mkdir("/tmp/ppp/fw", 0777);

	if (nvram_get_int("ppp3g_en")) {

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
		//eval("switch3g");

		// create ip-up script
		if ((f = fopen("/tmp/ppp/ip-up", "w")) != NULL) {
			fprintf(f, "#!/bin/sh\n"
				"echo \"#!/bin/sh\" > /tmp/ppp/fw/ppp3g-up-fw.sh\n"
				"echo \"iptables -I INPUT -i $1 -j ACCEPT\" >> /tmp/ppp/fw/ppp3g-up-fw.sh\n"
				"echo \"iptables -I FORWARD -i $1 -j ACCEPT\" >> /tmp/ppp/fw/ppp3g-up-fw.sh\n"
				"echo \"iptables -t nat -I POSTROUTING -o $1 -j MASQUERADE\" >> /tmp/ppp/fw/ppp3g-up-fw.sh\n"
				"chmod 0755 /tmp/ppp/fw/ppp3g-up-fw.sh\n"
				"/tmp/ppp/fw/ppp3g-up-fw.sh\n" );
			if (nvram_get_int("ppp3g_route") == 0) { // custom
				fprintf(f, "%s\n", nvram_safe_get("ppp3g_ipup"));
			}
			else if (nvram_get_int("ppp3g_route") == 1) { // default
				fprintf(f, "route add default gw $5\n");
			}
			else if (nvram_get_int("ppp3g_route") == 2) { // facebook
				fprintf(f, "for ip in `whois -h whois.radb.net '!gAS32934' | grep /`\n"
					"do\n"
					"	route add -net $ip dev $1 gw $5\n"
					"done\n" );
			}
			fclose(f);
			chmod("/tmp/ppp/ip-up", 0755);
		}

		// create ip-down script
		if ((f = fopen("/tmp/ppp/ip-down", "w")) != NULL) {
			fprintf(f,"#!/bin/sh\n"
				"echo \"#!/bin/sh\" > /tmp/ppp/fw/ppp3g-down-fw.sh\n"
				"echo \"iptables -D INPUT -i $1 -j ACCEPT\" >> /tmp/ppp/fw/ppp3g-down-fw.sh\n"
				"echo \"iptables -D FORWARD -i $1 -j ACCEPT\" >> /tmp/ppp/fw/ppp3g-down-fw.sh\n"
				"echo \"iptables -t nat -D POSTROUTING -o $1 -j MASQUERADE\" >> /tmp/ppp/fw/ppp3g-down-fw.sh\n"
				"chmod 0755 /tmp/ppp/fw/ppp3g-down-fw.sh\n"
				"/tmp/ppp/fw/ppp3g-down-fw.sh\n" );
			if (nvram_get_int("ppp3g_route") == 0) { // custom
				fprintf(f, "%s\n", nvram_safe_get("ppp3g_ipdown"));
			}
			else if (nvram_get_int("ppp3g_route") == 1) { // default
				fprintf(f, "route del default gw $5\n");
			}
			else if (nvram_get_int("ppp3g_route") == 2) { // facebook
				fprintf(f, "for ip in `whois -h whois.radb.net '!gAS32934' | grep /`\n"
					"do\n"
					"	route del -net $ip dev $1 gw $5\n"
					"done\n" );
			}
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

