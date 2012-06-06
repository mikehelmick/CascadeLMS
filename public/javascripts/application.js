

// warn when editing form
var formChecked = false
var formNeedsChecked = false

function set_form_needs_checked() {
	formNeedsChecked = true
}

function initialize_check_form() {
	formChecked = false
	formNeedsChecked = false
}

function set_form_submitted() {
	formChecked = true
}

function check_form_submitted() {
	if (formNeedsChecked && !formChecked) {
	  return "This form contains unsaved work. Would you like to save before exiting this page? Click OK to continue or cancel to return to editing this page."
    }
}

// Course jump
function changeCourse() {
	var cjForm = document.forms["course_jump"];
	location.href = cjForm.course_select_top.options[cjForm.course_select_top.selectedIndex].value;		
}


// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function blindToggle( area ) {
	elem = document.getElementById( area );
	if ( elem.style.display == 'none' ) {
		new Effect.BlindDown( area );
	} else {
		new Effect.BlindUp( area );
	}
}

/*- from shopify -*/

Element.Class = {
    // Element.toggleClass(element, className) toggles the class being on/off
    // Element.toggleClass(element, className1, className2) toggles between both classes,
    //   defaulting to className1 if neither exist
    toggle: function(element, className) {
      if(Element.Class.has(element, className)) {
        Element.Class.remove(element, className);
        if(arguments.length == 3) Element.Class.add(element, arguments[2]);
      } else {
        Element.Class.add(element, className);
        if(arguments.length == 3) Element.Class.remove(element, arguments[2]);
      }
    },

    // gets space-delimited classnames of an element as an array
    get: function(element) {
      return $(element).className.split(' ');
    },

    // functions adapted from original functions by Gavin Kistner
    remove: function(element) {
      element = $(element);
      var removeClasses = arguments;
      $R(1,arguments.length-1).each( function(index) {
        element.className = 
          element.className.split(' ').reject( 
            function(klass) { return (klass == removeClasses[index]) } ).join(' ');
      });
    },

    add: function(element) {
      element = $(element);
      for(var i = 1; i < arguments.length; i++) {
        Element.Class.remove(element, arguments[i]);
        element.className += (element.className.length > 0 ? ' ' : '') + arguments[i];
      }
    },

    // returns true if all given classes exist in said element
    has: function(element) {
      element = $(element);
      if(!element || !element.className) return false;
      var regEx;
      for(var i = 1; i < arguments.length; i++) {
        if((typeof arguments[i] == 'object') && 
          (arguments[i].constructor == Array)) {
          for(var j = 0; j < arguments[i].length; j++) {
            regEx = new RegExp("(^|\\s)" + arguments[i][j] + "(\\s|$)");
            if(!regEx.test(element.className)) return false;
          }
        } else {
          regEx = new RegExp("(^|\\s)" + arguments[i] + "(\\s|$)");
          if(!regEx.test(element.className)) return false;
        }
      }
      return true;
    },

    // expects arrays of strings and/or strings as optional paramters
    // Element.Class.has_any(element, ['classA','classB','classC'], 'classD')
    has_any: function(element) {
      element = $(element);
      if(!element || !element.className) return false;
      var regEx;
      for(var i = 1; i < arguments.length; i++) {
        if((typeof arguments[i] == 'object') && 
          (arguments[i].constructor == Array)) {
          for(var j = 0; j < arguments[i].length; j++) {
            regEx = new RegExp("(^|\\s)" + arguments[i][j] + "(\\s|$)");
            if(regEx.test(element.className)) return true;
          }
        } else {
          regEx = new RegExp("(^|\\s)" + arguments[i] + "(\\s|$)");
          if(regEx.test(element.className)) return true;
        }
      }
      return false;
    },

    childrenWith: function(element, className) {
      var children = $(element).getElementsByTagName('*');
      var elements = new Array();

      for (var i = 0; i < children.length; i++)
        if (Element.Class.has(children[i], className))
          elements.push(children[i]);

      return elements;
    }
}

Object.extend(Form.Element, {
  
  // Toggle height of a form input where element is the 
  // element that fired the event and target is the input you want 
  // to toggle.
  //
  toggleHeight: function(element, target, options) {
    var options = options || {};
    Element.Class.toggle(target, 'short', 'tall');
		Element.Class.toggle(element, 'less', 'more');
    if(element.innerHTML.toLowerCase() == "more room to type")
      element.innerHTML = "Less room to type";
    else
      element.innerHTML = "More room to type";
  }
});