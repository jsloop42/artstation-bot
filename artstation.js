// Main class object. Any variables passed from AppleScript will be a direct property of DL.
// Currently username, password is being added.
function DL() {}

DL.prototype.a = function() {
    console.log("ok")
}

DL.prototype.isProfileLoaded = function () {
    return document.querySelector('.artist-name').innerText != ""
}

DL.prototype.isProfileLoadedAfterAuth = function() {
    return document.querySelector("a[href='/users/sign_out']") != null &&
     document.querySelector("nav.navbar-artist-profile button[ng-authorized-click='showUserMessageModal()']") != null
}

DL.prototype.isSignedIn = function() {
    return document.querySelector("a[href='/users/sign_out']") != null
}

DL.prototype.signIn = function() {
    document.querySelector("a.sign-in-button").click()
    document.querySelector("#new_user input.email").value = DL.username
    document.querySelector("#new_user input.password").value = DL.password
    document.querySelector("#new_user button[type='submit']").click()
}

DL.prototype.message = function() {
    document.querySelector("nav.navbar-artist-profile button[ng-authorized-click='showUserMessageModal()']").click()  // Bring up the message dialog
    var textarea = document.querySelector("form[name=messageForm] textarea[ng-model='messageBody']")
    var cb = document.querySelector("input[value='general']")  // Find radio button with General and select it
    if (cb) cb.checked = true 
    textarea.value = DL.message   // Add message
    textarea.dispatchEvent(new Event('change'))  // Trigger field processing so that angular js adds the right directives
    document.querySelector("form[name=messageForm] div.btn-toolbar button[type='submit']").click()  // Send message
    console.log("message sent")
    return true
}

DL.prototype.init = function() {
    this.a()
    console.log("isSignedIn: " + this.isSignedIn()) 
    if (!this.isSignedIn()) {
        this.signIn()
    }
}

var dl = new DL()
//dl.init()
