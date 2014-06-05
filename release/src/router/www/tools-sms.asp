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

//Array with "The 7 bit defaultalphabet"
sevenbitdefault = new Array('@', '£', '$', '¥', 'è', 'é', 'ù', 'ì', 'ò', 'Ç', '\n', 'Ø', 'ø', '\r','Å', 'å','\u0394', '_', '\u03a6', '\u0393', '\u039b', '\u03a9', '\u03a0','\u03a8', '\u03a3', '\u0398', '\u039e','€', 'Æ', 'æ', 'ß', 'É', ' ', '!', '"', '#', '¤', '%', '&', '\'', '(', ')','*', '+', ',', '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7','8', '9', ':', ';', '<', '=', '>', '?', '¡', 'A', 'B', 'C', 'D', 'E','F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S','T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'Ä', 'Ö', 'Ñ', 'Ü', '§', '¿', 'a','b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o','p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'ä', 'ö', 'ñ','ü', 'à');

// helper function for HexToNum
function MakeNum(str) {
	if ((str >= '0') && (str <= '9')) {
		return str;
	}
	switch (str.toUpperCase()) {
		case "A": return 10;
		case "B": return 11;
		case "C": return 12;
		case "D": return 13;
		case "E": return 14;
		case "F": return 15;
		default:
		return 16;
   	}
	return 16;
}
// function to convert a Hexnumber into a 10base number
function HexToNum(numberS) {
	var tens = MakeNum(numberS.substring(0, 1));
	
	var ones = 0;
	if (numberS.length > 1) { // means two characters entered
		ones=MakeNum(numberS.substring(1,2));
	}
	if (ones == 'X') {
		return "00";
	}
	return  (tens * 16) + (ones * 1);
}
function phoneNumberMap(character) {
//	return character;
	if ((character >= '0') && (character <= '9')) {
		return character;
	}
	switch (character.toUpperCase()) {
		case '*':
			return 'A';
		case '#':
			return 'B';
		case 'A':
			return 'C';
		case 'B':
			return 'D';
		case 'C':
			return 'E';
//		case '+':
//			return '+'; // An exception to fit with current processing ...
		default:
			return 'F';
	}
	return 'F';
}

function phoneNumberUnMap(chararacter) {
	if ((chararacter >= '0') && (chararacter <= '9')) {
		return chararacter;
	}
	switch (chararacter) {
		case 10: return '*';
		case 11: return '#';
		case 12: return 'A';
		case 13: return 'B';
		case 14: return 'C';
		default:
			return 'F';
	}
	return 'F';
}
// function to convert semioctets to a string
function semiOctetToString(inp) {
	var out = "";	
	for(var i=0; i<inp.length; i=i+2)
	{
	  	var temp = inp.substring(i,i+2);	
		out = out + phoneNumberMap(temp.charAt(1)) + phoneNumberMap(temp.charAt(0));
	}
	return out;
}
// function te convert a bit string into a integer
function binToInt(x) {
	var total = 0;	
	var power = parseInt(x.length)-1;	

	for (var i=0; i<x.length; i++) {
		if(x.charAt(i) == '1') {
			total = total +Math.pow(2,power);
		}
		power --;
	}
	return total;
}
// function to convert a integer into a bit String
function intToBin(x, size) {
	var base = 2;
	var num = parseInt(x);
	var bin = num.toString(base);
	for (var i=bin.length; i<size; i++) {
		bin = "0" + bin;
	}
	return bin;
}
//Main function to translate the input to a "human readable" string
function getUserMessage(input, truelength) {
	var byteString = "";
	octetArray = new Array();
	restArray = new Array();
	septetsArray = new Array();
	var s=1;
	var count = 0;
	var matchcount = 0; // AJA
	var smsMessage = "";	
	
	//Cut the input string into pieces of2 (just get the hex octets)
	for (var i=0; i<input.length; i=i+2) {
		var hex = input.substring(i, i+2);
		byteString = byteString + intToBin(HexToNum(hex), 8);
	}
	
	// make two array's these are nessesery to
	for (var i=0; i<byteString.length; i=i+8) {
		octetArray[count] = byteString.substring(i, i+8);
		restArray[count] = octetArray[count].substring(0, (s%8));
		septetsArray[count] = octetArray[count].substring((s%8), 8);

		s++;
        	count++;
		if (s == 8) {
			s = 1;
		}
	}
		
	// put the right parts of the array's together to make the sectets
	for (var i=0; i<restArray.length; i++) {
		if (i%7 == 0) {	
			if (i != 0) {
				smsMessage = smsMessage + sevenbitdefault[binToInt(restArray[i-1])];
				matchcount ++; // AJA
			}
			smsMessage = smsMessage + sevenbitdefault[binToInt(septetsArray[i])];
			matchcount ++; // AJA
		}
		else {
			smsMessage = smsMessage +  sevenbitdefault[binToInt(septetsArray[i]+restArray[i-1])];
			matchcount ++; // AJA
		}
	
	}
	if (matchcount != truelength) {
		smsMessage = smsMessage + sevenbitdefault[binToInt(restArray[i-1])];
	}
	return smsMessage;
}

function getUserMessage16(input,truelength) {
	var smsMessage = "";	
	// Cut the input string into pieces of 4
	for (var i=0; i<input.length; i=i+4) {
		var hex1 = input.substring(i, i+2);
		var hex2 = input.substring(i+2, i+4);
		smsMessage += "" + String.fromCharCode(HexToNum(hex1)*256+HexToNum(hex2));
	}
	return smsMessage;
}

function getUserMessage8(input,truelength) {
	var smsMessage = "";	
	// Cut the input string into pieces of 2 (just get the hex octets)
	for (var i=0; i<input.length; i=i+2) {
		var hex = input.substring(i, i+2);
		smsMessage += "" + String.fromCharCode(HexToNum(hex));
	}
	return smsMessage;
}

function DCS_Bits(tp_DCS)
{
	var AlphabetSize = 7; // Set Default
	var pomDCS = HexToNum(tp_DCS); 	

	switch (pomDCS & 192) {
		case 0:
			if (pomDCS & 32) {
				// tp_DCS_desc="Compressed Text\n";
			}
			else {
				// tp_DCS_desc="Uncompressed Text\n";
			}
			switch (pomDCS & 12) {
				case 4:
					AlphabetSize = 8;
					break;
				case 8:
					AlphabetSize = 16;
					break;
			}
			break;
		case 192:
			switch(pomDCS & 0x30) {
				case 0x20:
					AlphabetSize = 16;
					break;
				case 0x30:
					if (pomDCS & 0x4) {
						// ;
					}
					else {
						AlphabetSize = 8;
					}
					break;
			}
			break;
	}
	return(AlphabetSize); 
}


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
	var i, j;
	var r;
	var s = new Array();
	//var stats = '';

	var msg = '';
	var start = 0;

	//sms = null;
	this.removeAllData();
	
	for (i = 0; i < buf.length; ++i) {
		if (buf[i] == "AT+CMGL=4") {
			start = 1;
		}
		else if (buf[i] == "OK") {
			//alert(message);
			start = 1;
		}
		//else if (r = buf[i].match(/\+CMGL: (\d+),"(.+)","(.+)",,"(.+)"/)) {
		else if (r = buf[i].match(/\+CMGL: (\d+),(\d+),,(\d+)/)) {
			s[0] = r[1]; // id
			//s[1] = r[4]; // date
			//s[2] = r[3]; // from
			//s[3] = buf[++i] + '<br>'; // message
			
			var PDUString = buf[++i];
			var SMSC_lengthInfo = HexToNum(PDUString.substring(0, 2));
			var SMSC_info = PDUString.substring(2, 2+(SMSC_lengthInfo*2));
			var SMSC_TypeOfAddress = SMSC_info.substring(0, 2);
			var SMSC_Number = SMSC_info.substring(2, 2+(SMSC_lengthInfo*2));

			if (SMSC_lengthInfo != 0) {
				SMSC_Number = semiOctetToString(SMSC_Number);
		       
				// if the length is odd remove the trailing  F
				if((SMSC_Number.substr(SMSC_Number.length-1,1) == 'F') || (SMSC_Number.substr(SMSC_Number.length-1,1) == 'f')) {
					SMSC_Number = SMSC_Number.substring(0,SMSC_Number.length-1);
				}
				if (SMSC_TypeOfAddress == 91) {
					SMSC_Number = "+" + SMSC_Number;
				}
			}

			var start_SMSDeleivery = (SMSC_lengthInfo*2) + 2;
			start = start_SMSDeleivery;
			var firstOctet_SMSDeliver = PDUString.substr(start, 2);
			start += 2;

			var tp_UDHI = (HexToNum(firstOctet_SMSDeliver) >> 6) & 1;
			// length in decimals
			var sender_addressLength = HexToNum(PDUString.substr(start, 2));
			start += 2;
			var sender_typeOfAddress = PDUString.substr(start, 2);
			start += 2;
			var sender_number;
			if (sender_typeOfAddress == "D0") {
				_sl = sender_addressLength;
				if (sender_addressLength%2 != 0) {
					sender_addressLength += 1;
				}
				sender_number = getUserMessage(PDUString.substring(start, start+sender_addressLength), parseInt(_sl/2*8/7));
			}
			else {
				if (sender_addressLength%2 != 0) {
					sender_addressLength += 1;
				}
				sender_number = semiOctetToString(PDUString.substring(start, start+sender_addressLength));
				if ((sender_number.substr(sender_number.length-1, 1) == 'F') || (sender_number.substr(sender_number.length-1, 1) == 'f' )) {
					sender_number =	sender_number.substring(0, sender_number.length-1);
				}
				if (sender_typeOfAddress == 91) {
					sender_number = "+" + sender_number;
				}
			}
			start += sender_addressLength;
			var tp_PID = PDUString.substr(start, 2);
			start += 2;
			var tp_DCS = PDUString.substr(start, 2);
			if (tp_DCS == 'F1') { tp_DCS = '00'; } // kerpz haxx
			//var tp_DCS_desc = tpDCSMeaning(tp_DCS);  
			start += 2;
	    
			var timeStamp = semiOctetToString(PDUString.substr(start, 14));
	
			// get date	
			var year = timeStamp.substring(0, 2);
			var month = timeStamp.substring(2, 4);
			var day = timeStamp.substring(4, 6);
			var hours = timeStamp.substring(6 ,8);
			var minutes = timeStamp.substring(8, 10);
			var seconds = timeStamp.substring(10, 12);

			timeStamp = day + "/" + month + "/" + year + " " + hours + ":" + minutes + ":" + seconds; //+" + timezone/4;
			
			start += 14;

			var messageLength = HexToNum(PDUString.substr(start, 2));
			start += 2;

			var bitSize = DCS_Bits(tp_DCS);
			var userData = "Undefined format";

			if (bitSize == 7) {
				userData = getUserMessage(PDUString.substr(start, PDUString.length-start), messageLength);
			}
			else if (bitSize == 8) {
				userData = getUserMessage8(PDUString.substr(start, PDUString.length-start), messageLength);
			}
			else if (bitSize == 16) {
				userData = getUserMessage16(PDUString.substr(start, PDUString.length-start), messageLength);
			}

			if (tp_UDHI) {
				var UDH_len = HexToNum(PDUString.substr(start, 2)) + 2;
				start += 8;
				var MSG_total = HexToNum(PDUString.substr(start, 2));
				start += 2;
				var MSG_part = HexToNum(PDUString.substr(start, 2));
				userData = MSG_part+' / '+MSG_total+' '+userData.substr(UDH_len, messageLength);
			}
			else {
				userData = userData.substr(0, messageLength);
			}

			if (bitSize == 16) {
				messageLength /= 2;
			}

			//out +=  "SMSC#"+SMSC_Number+"\nSender:"+sender_number+"\nTimeStamp:"+timeStamp+"\nTP_UDHI:"+tp_UDHI+"\nTP_PID:"+tp_PID+"\nTP_DCS:"+tp_DCS+"\nTP_DCS-popis:"+tp_DCS_desc+"\n"+userData+"\nLength:"+messageLength;

			s[1] = timeStamp; // date
			s[2] = sender_number; // from
			s[3] = userData; // message
			/*
			j = i;
			while (!buf[++j].match(/\+CMGL:/g)) {
				if (buf[j] == "OK") break;
				s[3] = s[3] + buf[j]  + '<br>';
				i = j;
			}
			*/
			this.insert(-1, s, s, false);
		}
	}
               
	this.resort(1);

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
		eval(text);
		pg.populate();
		sms = null;
	}
	sms.onError = function(x) {
		alert('error: ' + x);
		spin(0);
	}

	sms.post('sms.cgi', 'read=all&delete=' + PR(e).cells[0].innerHTML);
}

function verifyFields(focused, quiet)
{
	save();
}

var sms = null;

function spin(x)
{
	E('sendb').disabled = x;
	E('refreshb').disabled = x;
	E('_f_number').disabled = x;
	E('_f_message').disabled = x;
	E('sendspin').style.visibility = x ? 'visible' : 'hidden';
	E('refreshspin').style.visibility = x ? 'visible' : 'hidden';
}

function sendsms()
{
	// Opera 8 sometimes sends 2 clicks
	if (sms) return;

	//if (!verifyFields(null, 0)) return;

	var number = E('_f_number').value;
	var message = E('_f_message').value;

	if (number == '') {
		alert('Error: Invalid destination number');
		return;
	}
	if (message.length > 160) {
		alert('Error: Message exceeds 160 characters!');
		return;
	}

	spin(1);

	sms = new XmlHttp();
	sms.onCompleted = function(text, xml) {
		eval(text);
		pg.populate();
		sms = null;
		E('_f_number').value = '';
		E('_f_message').value = '';
	}
	sms.onError = function(x) {
		alert('error: ' + x);
		spin(0);
	}

	sms.post('sms.cgi', 'read=all&number=' + number + '&message=' + message);
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
	readsms();
}

function save()
{
	var fom = E('_fom');
	//alert(fom.sms_dev.value);
	form.submit(fom, 1);
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
</script>

</div>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>&nbsp;</td></tr>
</table>
</form>
<script type='text/javascript'>pg.setup()</script>
</body>
</html>

