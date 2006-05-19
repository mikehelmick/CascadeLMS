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