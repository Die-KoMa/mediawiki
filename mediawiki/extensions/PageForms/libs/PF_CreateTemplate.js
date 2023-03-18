var fieldNum = 1;
function createTemplateAddField() {
	fieldNum++;
	var newField = jQuery( '#starterField' ).clone().css( 'display', '' ).removeAttr( 'id' );
	var newHTML = newField.html().replace(/starter/g, fieldNum);
	newField.html( newHTML );
	newField.find( ".deleteField" ).click( function () {
		// Remove the encompassing div for this instance.
		jQuery( this ).closest( ".fieldBox" )
			.fadeOut( 'fast', function () {
				jQuery(this).remove();
			} );
	} );
	newField.find( ".isList" ).click( function () {
		jQuery( this ).closest( ".fieldBox" ).find( ".delimiter" ).toggle();
	} );
	var combobox = new pf.select2.combobox();
	combobox.apply( $( newField.find( '.pfComboBox' ) ) );
	jQuery( '#fieldsList' ).append( newField );
}

function validateCreateTemplateForm() {
	var templateName = jQuery( '#template_name' ).val();
	if ( templateName === '' ) {
		scroll( 0, 0 );
		jQuery( '#template_name_p' ).append( '<span class="error">' + mediaWiki.msg( 'pf_blank_error' ) + '</span>' );
		return false;
	} else {
		return true;
	}
}

jQuery( document ).ready( function () {
	jQuery( ".createTemplateAddField" ).click( function () {
		createTemplateAddField();
	} );
	jQuery( ".deleteField" ).click( function () {
		// Remove the encompassing div for this instance.
		jQuery( this ).closest( ".fieldBox" )
			.fadeOut( 'fast', function () {
				jQuery( this ).remove();
			} );
	} );
	jQuery( ".isList" ).click( function () {
		jQuery( this ).closest( ".fieldBox" ).find( ".delimiter" ).toggle();
	} );
	jQuery( '#createTemplateForm' ).submit( function () {
		return validateCreateTemplateForm();
	} );
} );
