/*
 * Log_style.js
 * Javascript file for logging for Adanna.
 * Written by: Nathan Lane
 * Last Updated: 05/07/2007
 * Copyright (C) 2007, Vehix.com
 */

function showAll() {
	document.getElementById("passState").className = passTitleStyle;
	document.getElementById("pass").className = passStyle;
	document.getElementById("failState").className = failTitleStyle;
	document.getElementById("fail").className = failStyle;
	document.getElementById("doneState").className = doneTitleStyle;
	document.getElementById("done").className = doneStyle;
}

function showPass() {
	document.getElementById("passState").className = passTitleStyle;
	document.getElementById("pass").className = passStyle;
	document.getElementById("failState").className = invisibleMessage;
	document.getElementById("fail").className = invisibleMessage;
	document.getElementById("doneState").className = invisibleMessage;
	document.getElementById("done").className = invisibleMessage;
}

function showPassAndFail() {
	document.getElementById("passState").className = passTitleStyle;
	document.getElementById("pass").className = passStyle;
	document.getElementById("failState").className = failTitleStyle;
	document.getElementById("fail").className = failStyle;
	document.getElementById("doneState").className = invisibleMessage;
	document.getElementById("done").className = invisibleMessage;
}

function showFail() {
	document.getElementById("passState").className = invisibleMessage;
	document.getElementById("pass").className = invisibleMessage;
	document.getElementById("failState").className = failTitleStyle;
	document.getElementById("fail").className = failStyle;
	document.getElementById("doneState").className = invisibleMessage;
	document.getElementById("done").className = invisibleMessage;
}

function showDone() {
	document.getElementById("passState").className = invisibleMessage;
	document.getElementById("pass").className = invisibleMessage;
	document.getElementById("failState").className = invisibleMessage;
	document.getElementById("fail").className = invisibleMessage;
	document.getElementById("doneState").className = doneTitleStyle;
	document.getElementById("done").className = doneStyle;
}
