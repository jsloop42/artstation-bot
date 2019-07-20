// The main class
function ArtStationBot() {}

// Alias
var ASB = ArtStationBot
ASB.messageHandlerName = "asb"
ASB.msg = webkit.messageHandlers[ASB.messageHandlerName]

// Functions

ASB.prototype.greet = function() {
    ASB.msg.postMessage({"id": "greet", "msg": "hello world"})
}

ASB.prototype.init = function() {
    ASB.msg.postMessage({"id": "document-url", "value": document.URL})
}

ASB.prototype.getCount = function() {
    ASB.msg.postMessage({"id": "main-nav-len", "value": document.querySelector('.fixed-main-nav').classList.value.length})
}

var asb = new ASB()
asb.greet()
