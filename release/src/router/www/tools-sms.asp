<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] Tools: SMS</title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<% css(); %>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->

<style type='text/css'>
#tp-grid .co1 {
	width: 30px;
}
#tp-grid .co2 {
	width: 130px;
}
#tp-grid .co3 {
	width: 110px;
}
#tp-grid .co4, {
	text-align: right;
}
</style>

<script type='text/javascript' src='debug.js'></script>

<script type='text/javascript'>

//	<% nvram("sms_dev"); %>	// http_id

var smsdata = '';

var pg = new TomatoGrid();
pg.setup = function() {
	this.init('tp-grid', 'sort');
	this.canDelete = true;
	this.sortAscending = false;
	this.headerSet(['ID', 'Date', 'From', 'Message']);
}
pg.populate = function()
{
	var buf = smsdata.split('\n');
	var i;
	var r;
	var s = new Array();
	//var stats = '';

	var msg = '';
	var start = 0;

/* REMOVE-BEGIN
AT+CMGL="ALL"
+CMGL: 0,"REC READ","7176796669",,"14/03/15,13:08:06+32"
Message here
+CMGL: 1,"REC READ","7176796669",,"14/03/15,11:59:47+32"
Message here
OK
REMOVE-END */


	//sms = null;
	this.removeAllData();
	
	for (i = 0; i < buf.length; ++i) {
		if (buf[i] == "AT+CMGL=\"ALL\"") {
			start = 1;
		}
		else if (buf[i] == "OK") {
			//alert(message);
			start = 1;
		}
		else if (r = buf[i].match(/\+CMGL: (\d+),"(.+)","(.+)",,"(.+)"/)) {
			s[0] = r[1];
			s[1] = r[4];
			s[2] = r[3];
			s[3] = buf[++i];
			this.insert(-1, s, s, false);
		}
	}
               
	this.resort(1);

	//E('stats').innerHTML = stats;
	//E('debug').value = smsdata;
	smsdata = '';
	spin(0);
}
pg.rpDel = function(e)
{
	// Opera 8 sometimes sends 2 clicks
	if (sms) return;

	spin(1);

	sms = new XmlHttp();
	sms.onCompleted = function(text, xml) {
		spin(0);
		sms = null;
	}
	sms.onError = function(x) {
		alert('error: ' + x);
		spin(0);
	}

	sms.post('sms.cgi', 'delete=' + PR(e).cells[0].innerHTML);
}

var sms = null;

function spin(x)
{
	E('sendb').disabled = x;
	E('refreshb').disabled = x;
	E('_f_number').disabled = x;
	E('_f_message').disabled = x;
	//E('_f_size').disabled = x;
	E('sendspin').style.visibility = x ? 'visible' : 'hidden';
	E('refreshspin').style.visibility = x ? 'visible' : 'hidden';
	//if (!x) sms = null;
}

function sendsms()
{
	// Opera 8 sometimes sends 2 clicks
	if (sms) return;

	//if (!verifyFields(null, 0)) return;

	var number = E('_f_number').value;
	var message = E('_f_message').value;

	spin(1);

	sms = new XmlHttp();
	sms.onCompleted = function(text, xml) {
		//eval(text);
		spin(0);
		sms = null;
		//pg.populate();
	}
	sms.onError = function(x) {
		alert('error: ' + x);
		spin(0);
	}

	sms.post('sms.cgi', 'number=' + number + '&message=' + message);

	//cookie.set('smsnumber', number);
	//cookie.set('smsmessage', message);
}

function readsms()
{
	// Opera 8 sometimes sends 2 clicks
	if (sms) return;

	spin(1);

	sms = new XmlHttp();
	sms.onCompleted = function(text, xml) {
		eval(text);
		pg.populate();
		sms = null;
	}
	sms.onError = function(x) {
		alert('error: ' + x);
		spin(0);
	}
	sms.post('sms.cgi', 'read=all');
}

function init()
{
	//var s;

	//if ((s = cookie.get('smsnumber')) != null) E('_f_number').value = s;
	//if ((s = cookie.get('smsmessage')) != null) E('_f_message').value = s;

	//E('_f_number').onkeypress = function(ev) { if (checkEvent(ev).keyCode == 13) sendsms(); }
	
	readsms();
}

function save()
{
	alert("TODO");
}
</script>

</head>
<body onload='init()'>
<form id='_fom' method='post' action='tomato.cgi'>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'>Version <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<div class='section-title'>Send SMS</div>
<div class='section'>
<script type='text/javascript'>
createFieldTable('', [
	{ title: 'Number', name: 'f_number', type: 'text', maxlen: 32, size: 32, value: ''},
	{ title: 'Message', name: 'f_message', type: 'textarea', value: '' }
]);
</script>
<div style='float:right'><img src='spin.gif' id='sendspin' style='vertical-align:middle;visibility:hidden'> &nbsp; <input type='button' value='Send' onclick='sendsms()' id='sendb'></div>
</div>

<div class='section-title'>Read SMS</div>
<div class='section'>
	<table id='tp-grid' class='tomato-grid' cellspacing=1 style="table-layout:fixed; word-wrap:break-word;"></table>
	<div style='float:right'><img src='spin.gif' id='refreshspin' style='vertical-align:middle;visibility:hidden'> &nbsp; <input type='button' value='Refresh' onclick='readsms()' id='refreshb'></div>
</div>

<div class='section-title'>Modem device</div>
<div class='section'>
<script type='text/javascript'>
createFieldTable('', [
	{ title: 'Modem device', name: 'sms_dev', type: 'select', options: [['ttyUSB0', '/dev/ttyUSB0'],['ttyUSB1', '/dev/ttyUSB1'],['ttyUSB2', '/dev/ttyUSB2'],['ttyUSB3', '/dev/ttyUSB3'],['ttyUSB4', '/dev/ttyUSB4'],['ttyUSB5', '/dev/ttyUSB5'],['ttyUSB6', '/dev/ttyUSB6'],['ttyACM0', '/dev/ttyACM0']], value: nvram.sms_dev },
]);
W("<div style='float:right'><input type='button' onclick='save()' value='Save' id='saveb'></div>");
</script>
</div>

<!--
<pre id='stats'></pre>

<div style='height:10px;' onclick='javascript:E("debug").style.display=""'></div>
<textarea id='debug' style='width:99%;height:300px;display:none'></textarea>
-->

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>&nbsp;</td></tr>
</table>
</form>
<script type='text/javascript'>pg.setup()</script>
</body>
</html>

