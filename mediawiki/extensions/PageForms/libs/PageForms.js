/**
 * PageForms.js
 *
 * Javascript utility functions for the Page Forms extension.
 *
 * @author Yaron Koren
 * @author Sanyam Goyal
 * @author Stephan Gambke
 * @author Jeffrey Stuckman
 * @author Harold Solbrig
 * @author Eugene Mednikov
 */
/*global wgPageFormsShowOnSelect, wgPageFormsFieldProperties, wgPageFormsCargoFields, wgPageFormsDependentFields, validateAll, alert, mwTinyMCEInit, pf, Sortable*/

// Activate autocomplete functionality for the specified field
( function ( $, mw ) {

/* extending jQuery functions for custom highlighting */
$.ui.autocomplete.prototype._renderItem = function( ul, item) {

	var delim = this.element[0].delimiter;
	var term;
	if ( delim === null ) {
		term = this.term;
	} else {
		term = this.term.split( delim ).pop();
	}
	var re = new RegExp("(?![^&;]+;)(?!<[^<>]*)(" +
		term.replace(/([\^\$\(\)\[\]\{\}\*\.\+\?\|\\])/gi, "\\$1") +
		")(?![^<>]*>)(?![^&;]+;)", "gi");
	// HTML-encode the value's label.
	var itemLabel = $('<div/>').text(item.label).html();
	var loc = itemLabel.search(re);
	var t;
	if (loc >= 0) {
		t = itemLabel.substr(0, loc) +
			'<strong>' + itemLabel.substr(loc, term.length) + '</strong>' +
			itemLabel.substr(loc + term.length);
	} else {
		t = itemLabel;
	}
	return $( "<li></li>" )
		.data( "item.autocomplete", item )
		.append( " <a>" + t + "</a>" )
		.appendTo( ul );
};

$.fn.attachAutocomplete = function() {
	try {
	return this.each(function() {
		// Get all the necessary values from the input's "autocompletesettings"
		// attribute. This should probably be done as three separate attributes,
		// instead.
		var field_string = $(this).attr("autocompletesettings");

		if ( typeof field_string === 'undefined' ) {
			return;
		}

		var field_values = field_string.split(',');
		var delimiter = null;
		var data_source = field_values[0];
		if (field_values[1] === 'list') {
			delimiter = ",";
			if (field_values[2] !== null && field_values[2] !== '' && field_values[2] !== undefined) {
				delimiter = field_values[2];
			}
		}

		// Modify the delimiter. If it's "\n", change it to an actual
		// newline - otherwise, add a space to the end.
		// This doesn't cover the case of a delimiter that's a newline
		// plus something else, like ".\n" or "\n\n", but as far as we
		// know no one has yet needed that.
		if ( delimiter !== null && delimiter !== '' && delimiter !== undefined ) {
			if ( delimiter === "\\n" ) {
				delimiter = "\n";
			} else {
				delimiter += " ";
			}
		}
		// Store this value within the object, so that it can be used
		// during highlighting of the search term as well.
		this.delimiter = delimiter;

		/* extending jQuery functions */
		$.extend( $.ui.autocomplete, {
			filter: function(array, term) {
				var wgPageFormsAutocompleteOnAllChars = mw.config.get( 'wgPageFormsAutocompleteOnAllChars' );
				var matcher;
				if ( wgPageFormsAutocompleteOnAllChars ) {
					matcher = new RegExp($.ui.autocomplete.escapeRegex(term), "i" );
				} else {
					matcher = new RegExp("(^|\\s)" + $.ui.autocomplete.escapeRegex(term), "i" );
				}
				// This may be an associative array instead of a
				// regular one - grep() requires a regular one.
				// (Is this "if" check necessary, or useful?)
				if ( typeof array === 'object' ) {
					// Unfortunately, Object.values() is
					// not supported on all browsers.
					array = Object.keys(array).map(function(key) {
						return array[key];
					});
				}
				return $.grep( array, function(value) {
					return matcher.test( value.label || value.value || value );
				});
			}
		} );

		var values = $(this).data('autocompletevalues');
		if ( !values ) {
			var wgPageFormsAutocompleteValues = mw.config.get( 'wgPageFormsAutocompleteValues' );
			values = wgPageFormsAutocompleteValues[field_string];
		}
		var split = function (val) {
			return val.split(delimiter);
		};
		var extractLast = function (term) {
			return split(term).pop();
		};
		if (values !== null && values !== undefined) {
			// Local autocompletion

			if (delimiter !== null && delimiter !== undefined) {
				// Autocomplete for multiple values

				var thisInput = $(this);

				$(this).autocomplete({
					minLength: 0,
					source: function(request, response) {
						// We need to re-get the set of values, since
						// the "values" variable gets overwritten.
						values = thisInput.data( 'autocompletevalues' );
						if ( !values ) {
							values = wgPageFormsAutocompleteValues[field_string];
						}
						response($.ui.autocomplete.filter(values, extractLast(request.term)));
					},
					focus: function() {
						// prevent value inserted on focus
						return false;
					},
					select: function(event, ui) {
						var terms = split( this.value );
						// remove the current input
						terms.pop();
						// add the selected item
						terms.push( ui.item.value );
						// add placeholder to get the comma-and-space at the end
						terms.push("");
						this.value = terms.join(delimiter);
						return false;
					}
				});

			} else {
				// Autocomplete for a single value
				$(this).autocomplete({
					// Unfortunately, Object.values() is
					// not supported on all browsers.
					source: ( typeof values === 'object' ) ? Object.keys(values).map(function(key) { return values[key]; }) : values
				});
			}
		} else {
			// Remote autocompletion.
			var myServer = mw.util.wikiScript( 'api' );
			var autocomplete_type = $(this).attr("autocompletedatatype");
			if ( autocomplete_type === 'cargo field' ) {
				var table_and_field = data_source.split('|');
				myServer += "?action=pfautocomplete&format=json&cargo_table=" + table_and_field[0] + "&cargo_field=" + table_and_field[1];
			} else {
				myServer += "?action=pfautocomplete&format=json&" + autocomplete_type + "=" + data_source;
			}

			if (delimiter !== null && delimiter !== undefined) {
				$(this).autocomplete({
					source: function(request, response) {
						$.getJSON(myServer, {
							substr: extractLast(request.term)
						}, function( data ) {
							response($.map(data.pfautocomplete, function(item) {
								return {
									value: item.title
								};
							}));
						});
					},
					search: function() {
						// custom minLength
						var term = extractLast(this.value);
						if (term.length < 1) {
							return false;
						}
					},
					focus: function() {
						// prevent value inserted on focus
						return false;
					},
					select: function(event, ui) {
						var terms = split( this.value );
						// remove the current input
						terms.pop();
						// add the selected item
						terms.push( ui.item.value );
						// add placeholder to get the comma-and-space at the end
						terms.push("");
						this.value = terms.join(delimiter);
						return false;
					}
				} );
			} else {
				$(this).autocomplete({
					minLength: 1,
					source: function(request, response) {
						$.ajax({
							url: myServer,
							dataType: "json",
							data: {
								substr:request.term
							},
							success: function( data ) {
								response($.map(data.pfautocomplete, function(item) {
									return {
										value: item.title
									};
								}));
							}
						});
					},
					open: function() {
						$(this).removeClass("ui-corner-all").addClass("ui-corner-top");
					},
					close: function() {
						$(this).removeClass("ui-corner-top").addClass("ui-corner-all");
					}
				} );
			}
		}
	});
	} catch ( error ) {
		// Autocompletion (and specifically, the call to
		// this.menu.element in line 195 of jquery.ui.autocomplete.js)
		// for some reason sometimes fails when doing a preview of the
		// form definition. It's not that importatnt, so, in lieu of
		// showing it to the user (or debugging it), we'll just catch
		// the error and log it in the console.
		window.console.log("Error setting autocompletion: " + error);
	}
};



/*
 * Functions to register/unregister methods for the initialization and
 * validation of inputs.
 */

// Initialize data object to hold initialization and validation data
function setupPF() {

	$("#pfForm").data("PageForms",{
		initFunctions : [],
		validationFunctions : []
	});

}

// Register a validation method
//
// More than one method may be registered for one input by subsequent calls to
// PageForms_registerInputValidation.
//
// Validation functions and their data are stored in a numbered array
//
// @param valfunction The validation functions. Must take a string (the input's id) and an object as parameters
// @param param The parameter object given to the validation function
$.fn.PageForms_registerInputValidation = function(valfunction, param) {

	if ( ! this.attr("id") ) {
		return this;
	}

	if ( ! $("#pfForm").data("PageForms") ) {
		setupPF();
	}

	$("#pfForm").data("PageForms").validationFunctions.push({
		input : this.attr("id"),
		valfunction : valfunction,
		parameters : param
	});

	return this;
};

// Register an initialization method
//
// More than one method may be registered for one input by subsequent calls to
// PageForms_registerInputInit. This method also executes the initFunction
// if the element referenced by /this/ is not part of a multipleTemplateStarter.
//
// Initialization functions and their data are stored in a associative array
//
// @param initFunction The initialization function. Must take a string (the input's id) and an object as parameters
// @param param The parameter object given to the initialization function
// @param noexecute If set, the initialization method will not be executed here
$.fn.PageForms_registerInputInit = function( initFunction, param, noexecute ) {

	// return if element has no id
	if ( ! this.attr("id") ) {
		return this;
	}

	// setup data structure if necessary
	if ( ! $("#pfForm").data("PageForms") ) {
		setupPF();
	}

	// if no initialization function for this input was registered yet,
	// create entry
	if ( ! $("#pfForm").data("PageForms").initFunctions[this.attr("id")] ) {
		$("#pfForm").data("PageForms").initFunctions[this.attr("id")] = [];
	}

	// record initialization function
	$("#pfForm").data("PageForms").initFunctions[this.attr("id")].push({
		initFunction : initFunction,
		parameters : param
	});

	// execute initialization if input is not part of multipleTemplateStarter
	// and if not forbidden
	if ( this.closest(".multipleTemplateStarter").length === 0 && !noexecute) {
		var input = this;
		// ensure initFunction is only executed after doc structure is complete
		$(function() {
			if ( initFunction !== undefined )  {
				initFunction ( input.attr("id"), param );
			}
		});
	}

	return this;
};

// Unregister all validation methods for the element referenced by /this/
$.fn.PageForms_unregisterInputValidation = function() {

	var pfdata = $("#pfForm").data("PageForms");

	if ( this.attr("id") && pfdata ) {
		// delete every validation method for this input
		for ( var i = 0; i < pfdata.validationFunctions.length; i++ ) {
			if ( typeof pfdata.validationFunctions[i] !== 'undefined' &&
				pfdata.validationFunctions[i].input === this.attr("id") ) {
				delete pfdata.validationFunctions[i];
			}
		}
	}

	return this;
};

// Unregister all initialization methods for the element referenced by /this/
$.fn.PageForms_unregisterInputInit = function() {

	if ( this.attr("id") && $("#pfForm").data("PageForms") ) {
		delete $("#pfForm").data("PageForms").initFunctions[this.attr("id")];
	}

	return this;
};

/*
 * Functions for handling 'show on select'
 */

// Display a div that would otherwise be hidden by "show on select".
function showDiv( div_id, instanceWrapperDiv, initPage ) {
	var speed = initPage ? 0 : 'fast';
	var elem;
	if ( instanceWrapperDiv !== null ) {
		elem = $('[data-origID="' + div_id + '"]', instanceWrapperDiv);
	} else {
		elem = $('#' + div_id);
	}

	elem
	.addClass('shownByPF')

	.find(".hiddenByPF")
	.removeClass('hiddenByPF')
	.addClass('shownByPF')

	.find(".disabledByPF")
	.prop('disabled', false)
	.removeClass('disabledByPF');

	elem.each( function() {
		if ( $(this).css('display') === 'none' ) {

			$(this).slideDown(speed, function() {
				$(this).fadeTo(speed,1);
			});

		}
	});

	// Now re-show any form elements that are meant to be shown due
	// to the current value of form inputs in this div that are now
	// being uncovered.
	var wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' );
	elem.find(".pfShowIfSelected, .pfShowIfChecked").each( function() {
		var uncoveredInput = $(this);
		var uncoveredInputID = null;
		if ( instanceWrapperDiv === null ) {
			uncoveredInputID = uncoveredInput.attr("id");
		} else {
			uncoveredInputID = uncoveredInput.attr("data-origID");
		}
		var showOnSelectVals = wgPageFormsShowOnSelect[uncoveredInputID];

		if ( showOnSelectVals !== undefined ) {
			var inputVal = uncoveredInput.val();
			for ( var i = 0; i < showOnSelectVals.length; i++ ) {
				var options = showOnSelectVals[i][0];
				var div_id2 = showOnSelectVals[i][1];
				if ( uncoveredInput.hasClass( 'pfShowIfSelected' ) ) {
					showDivIfSelected( options, div_id2, inputVal, instanceWrapperDiv, initPage );
				} else {
					uncoveredInput.showDivIfChecked( options, div_id2, instanceWrapperDiv, initPage );
				}
			}
		}
	});
}

// Hide a div due to "show on select". The CSS class is there so that PF can
// ignore the div's contents when the form is submitted.
function hideDiv( div_id, instanceWrapperDiv, initPage ) {
	var speed = initPage ? 0 : 'fast';
	var elem;
	// IDs can't contain spaces, and jQuery won't work with such IDs - if
	// this one has a space, display an alert.
	if ( div_id.indexOf( ' ' ) > -1 ) {
		// TODO - this should probably be a language value, instead of
		// hardcoded in English.
		alert( "Warning: this form has \"show on select\" pointing to an invalid element ID (\"" + div_id + "\") - IDs in HTML cannot contain spaces." );
	}

	if ( instanceWrapperDiv !== null ) {
		elem = instanceWrapperDiv.find('[data-origID=' + div_id + ']');
	} else {
		elem = $('#' + div_id);
	}

	// If we're just setting up the page, and this element has already
	// been marked to be shown by some other input, don't hide it.
	if ( initPage && elem.hasClass('shownByPF') ) {
		return;
	}

	elem.find("span, div").addClass('hiddenByPF');

	elem.each( function() {
		if ( $(this).css('display') !== 'none' ) {

			// if 'display' is not 'hidden', but the element is hidden otherwise
			// (e.g. by having height = 0), just hide it, else animate the hiding
			if ( $(this).is(':hidden') ) {
				$(this).hide();
			} else {
				$(this).fadeTo(speed, 0, function() {
					$(this).slideUp(speed);
				});
			}
		}
	});

	// Also, recursively hide further elements that are only shown because
	// inputs within this now-hidden div were checked/selected.
	var wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' );
	elem.find(".pfShowIfSelected, .pfShowIfChecked").each( function() {
		var showOnSelectVals;
		if ( instanceWrapperDiv === null ) {
			showOnSelectVals = wgPageFormsShowOnSelect[$(this).attr("id")];
		} else {
			showOnSelectVals = wgPageFormsShowOnSelect[$(this).attr("data-origID")];
		}

		if ( showOnSelectVals !== undefined ) {
			for ( var i = 0; i < showOnSelectVals.length; i++ ) {
				//var options = showOnSelectVals[i][0];
				var div_id2 = showOnSelectVals[i][1];
				hideDiv( div_id2, instanceWrapperDiv, initPage );
			}
		}
	});
}

// Show this div if the current value is any of the relevant options -
// otherwise, hide it.
function showDivIfSelected(options, div_id, inputVal, instanceWrapperDiv, initPage) {
	for ( var i = 0; i < options.length; i++ ) {
		// If it's a listbox and the user has selected more than one
		// value, it'll be an array - handle either case.
		if (($.isArray(inputVal) && $.inArray(options[i], inputVal) >= 0) ||
			(!$.isArray(inputVal) && (inputVal === options[i]))) {
			showDiv( div_id, instanceWrapperDiv, initPage );
			return;
		}
	}
	hideDiv( div_id, instanceWrapperDiv, initPage );
}

// Used for handling 'show on select' for the 'dropdown' and 'listbox' inputs.
$.fn.showIfSelected = function(partOfMultiple, initPage) {
	var inputVal = this.val(),
		wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' ),
		showOnSelectVals,
		instanceWrapperDiv;

	if ( partOfMultiple ) {
		showOnSelectVals = wgPageFormsShowOnSelect[this.attr("data-origID")];
		instanceWrapperDiv = this.closest('.multipleTemplateInstance');
	} else {
		showOnSelectVals = wgPageFormsShowOnSelect[this.attr("id")];
		instanceWrapperDiv = null;
	}

	if ( showOnSelectVals !== undefined ) {
		for ( var i = 0; i < showOnSelectVals.length; i++ ) {
			var options = showOnSelectVals[i][0];
			var div_id = showOnSelectVals[i][1];
			showDivIfSelected( options, div_id, inputVal, instanceWrapperDiv, initPage );
		}
	}

	return this;
};

// Show this div if any of the relevant selections are checked -
// otherwise, hide it.
$.fn.showDivIfChecked = function(options, div_id, instanceWrapperDiv, initPage ) {
	for ( var i = 0; i < options.length; i++ ) {
		if ($(this).find('[value="' + options[i] + '"]').is(":checked")) {
			showDiv( div_id, instanceWrapperDiv, initPage );
			return this;
		}
	}
	hideDiv( div_id, instanceWrapperDiv, initPage );

	return this;
};

// Used for handling 'show on select' for the 'checkboxes' and 'radiobutton'
// inputs.
$.fn.showIfChecked = function(partOfMultiple, initPage) {
	var wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' ),
		showOnSelectVals,
		instanceWrapperDiv,
		i;

	if ( partOfMultiple ) {
		showOnSelectVals = wgPageFormsShowOnSelect[this.attr("data-origID")];
		instanceWrapperDiv = this.closest('.multipleTemplateInstance');
	} else {
		showOnSelectVals = wgPageFormsShowOnSelect[this.attr("id")];
		instanceWrapperDiv = null;
	}

	if ( showOnSelectVals !== undefined ) {
		for ( i = 0; i < showOnSelectVals.length; i++ ) {
			var options = showOnSelectVals[i][0];
			var div_id = showOnSelectVals[i][1];
			this.showDivIfChecked( options, div_id, instanceWrapperDiv, initPage );
		}
	}

	return this;
};

// Used for handling 'show on select' for the 'checkbox' input.
$.fn.showIfCheckedCheckbox = function( partOfMultiple, initPage ) {
	var wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' ),
		divIDs,
		instanceWrapperDiv,
		i;

	if (partOfMultiple) {
		divIDs = wgPageFormsShowOnSelect[this.attr("data-origID")];
		instanceWrapperDiv = this.closest(".multipleTemplateInstance");
	} else {
		divIDs = wgPageFormsShowOnSelect[this.attr("id")];
		instanceWrapperDiv = null;
	}

	for ( i = 0; i < divIDs.length; i++ ) {
		var divID = divIDs[i];
		if ($(this).is(":checked")) {
			showDiv( divID, instanceWrapperDiv, initPage );
		} else {
			hideDiv( divID, instanceWrapperDiv, initPage );
		}
	}

	return this;
};

/*
 * Validation functions
 */

// Set the error message for an input.
$.fn.setErrorMessage = function(msg, val) {
	var container = this.find('.pfErrorMessages');
	container.html($('<div>').addClass( 'errorMessage' ).text( mw.msg( msg, val ) ));
};

// Append an error message to the end of an input.
$.fn.addErrorMessage = function(msg, val) {
	this.find('input').addClass('inputError');
	this.find('select2-container').addClass('inputError');
	this.append($('<div>').addClass( 'errorMessage' ).text( mw.msg( msg, val ) ));
	// If this is part of a minimized multiple-template instance, add a
	// red border around the instance rectangle to make it easier to find.
	this.parents( '.multipleTemplateInstance.minimized' ).css( 'border', '1px solid red' );
};

$.fn.isAtMaxInstances = function() {
	var numInstances = this.find("div.multipleTemplateInstance").length;
	var maximumInstances = this.attr("maximumInstances");
	if ( numInstances >= maximumInstances ) {
		this.parent().setErrorMessage( 'pf_too_many_instances_error', maximumInstances );
		return true;
	}
	return false;
};

$.fn.validateNumInstances = function() {
	var minimumInstances = this.attr("minimumInstances");
	var maximumInstances = this.attr("maximumInstances");
	var numInstances = this.find("div.multipleTemplateInstance").length;
	if ( numInstances < minimumInstances ) {
		this.parent().addErrorMessage( 'pf_too_few_instances_error', minimumInstances );
		return false;
	} else if ( numInstances > maximumInstances ) {
		this.parent().addErrorMessage( 'pf_too_many_instances_error', maximumInstances );
		return false;
	} else {
		return true;
	}
};

$.fn.validateMandatoryField = function() {
	var fieldVal = this.find(".mandatoryField").val();
	var isEmpty;

	if (fieldVal === null) {
		isEmpty = true;
	} else if ($.isArray(fieldVal)) {
		isEmpty = (fieldVal.length === 0);
	} else {
		isEmpty = (fieldVal.replace(/\s+/, '') === '');
	}
	if (isEmpty) {
		this.addErrorMessage( 'pf_blank_error' );
		return false;
	} else {
		return true;
	}
};

$.fn.validateUniqueField = function() {

	var UNDEFINED = "undefined";
	var field = this.find(".uniqueField");
	var fieldVal = field.val();

	if (typeof fieldVal === UNDEFINED || fieldVal.replace(/\s+/, '') === '') {
		return true;
	}

	var fieldOrigVal = field.prop("defaultValue");
	if (fieldVal === fieldOrigVal) {
		return true;
	}

	var categoryFieldName = field.prop("id") + "_unique_for_category";
	var categoryField = $("[name=" + categoryFieldName + "]");
	var category = categoryField.val();

	var namespaceFieldName = field.prop("id") + "_unique_for_namespace";
	var namespaceField = $("[name=" + namespaceFieldName + "]");
	var namespace = namespaceField.val();

	var url = mw.config.get( 'wgScriptPath' ) + "/api.php?format=json&action=";

	var query,
		isNotUnique;

	// SMW
	var propertyFieldName = field.prop("id") + "_unique_property",
		propertyField = $("[name=" + propertyFieldName + "]"),
		property = propertyField.val();
	if (typeof property !== UNDEFINED && property.replace(/\s+/, '') !== '') {

		query = "[[" + property + "::" + fieldVal + "]]";

		if (typeof category !== UNDEFINED &&
			category.replace(/\s+/, '') !== '') {
			query += "[[Category:" + category + "]]";
		}

		if (typeof namespace !== UNDEFINED) {
			if (namespace.replace(/\s+/, '') !== '') {
				query += "[[:" + namespace + ":+]]";
			} else {
				query += "[[:+]]";
			}
		}

		var conceptFieldName = field.prop("id") + "_unique_for_concept";
		var conceptField = $("[name=" + conceptFieldName + "]");
		var concept = conceptField.val();
		if (typeof concept !== UNDEFINED &&
			concept.replace(/\s+/, '') !== '') {
			query += "[[Concept:" + concept + "]]";
		}

		query += "|limit=1";
		query = encodeURIComponent(query);

		url += "ask&query=" + query;
		isNotUnique = true;
		$.ajax({
			url: url,
			dataType: 'json',
			async: false,
			success: function(data) {
				if (data.query.meta.count === 0) {
					isNotUnique = false;
				}
			}
		});
		if (isNotUnique) {
			this.addErrorMessage( 'pf_not_unique_error' );
			return false;
		} else {
			return true;
		}
	}

	// Cargo
	var cargoTableFieldName = field.prop("id") + "_unique_cargo_table";
	var cargoTableField = $("[name=" + cargoTableFieldName + "]");
	var cargoTable = cargoTableField.val();
	var cargoFieldFieldName = field.prop("id") + "_unique_cargo_field";
	var cargoFieldField = $("[name=" + cargoFieldFieldName + "]");
	var cargoField = cargoFieldField.val();
	if (typeof cargoTable !== UNDEFINED && cargoTable.replace(/\s+/, '') !== ''
		&& typeof cargoField !== UNDEFINED
		&& cargoField.replace(/\s+/, '') !== '') {

		query = "&where=" + cargoField + "+=+'" + fieldVal + "'";

		if (typeof category !== UNDEFINED &&
			category.replace(/\s+/, '') !== '') {
			category = category.replace(/\s/, '_');
			query += "+AND+cl_to=" + category + "+AND+cl_from=_pageID";
			cargoTable += ",categorylinks";
		}

		if (typeof namespace !== UNDEFINED) {
			query += "+AND+_pageNamespace=";
			if (namespace.replace(/\s+/, '') !== '') {
				var ns = mw.config.get('wgNamespaceIds')[namespace.toLowerCase()];
				if (typeof ns !== UNDEFINED) {
					query += ns;
				}
			} else {
				query += "0";
			}
		}

		query += "&limit=1";

		url += "cargoquery&tables=" + cargoTable + "&fields=" + cargoField +
			query;
		isNotUnique = true;
		$.ajax({
			url: url,
			dataType: 'json',
			async: false,
			success: function(data) {
				if (data.cargoquery.length === 0) {
					isNotUnique = false;
				}
			}
		});
		if (isNotUnique) {
			this.addErrorMessage( 'pf_not_unique_error' );
			return false;
		} else {
			return true;
		}
	}

	return true;

};

$.fn.validateMandatoryComboBox = function() {
	var combobox = this.find('.mandatoryField');
	if (combobox.val() === null) {
		this.addErrorMessage( 'pf_blank_error' );
		return false;
	} else {
		return true;
	}
};

$.fn.validateMandatoryDateField = function() {
	if (this.find(".dayInput").val() === '' ||
		this.find(".monthInput").val() === '' ||
		this.find(".yearInput").val() === '') {
		this.addErrorMessage( 'pf_blank_error' );
		return false;
	} else {
		return true;
	}
};

$.fn.validateMandatoryRadioButton = function() {
	var checkedValue = this.find("input:checked").val();
	if ( !checkedValue || checkedValue == '' ) {
		this.addErrorMessage( 'pf_blank_error' );
		return false;
	} else {
		return true;
	}
};

$.fn.validateMandatoryCheckboxes = function() {
	// Get the number of checked checkboxes within this span - must
	// be at least one.
	var numChecked = this.find("input:checked").size();
	if (numChecked === 0) {
		this.addErrorMessage( 'pf_blank_error' );
		return false;
	} else {
		return true;
	}
};

/*
 * Type-based validation
 */

$.fn.validateURLField = function() {
	var fieldVal = this.find("input").val();
	var url_protocol = mw.config.get( 'wgUrlProtocols' );
	//removing backslash before colon from url_protocol string
	url_protocol = url_protocol.replace( /\\:/, ':' );
	//removing '//' from wgUrlProtocols as this causes to match any protocol in regexp
	url_protocol = url_protocol.replace( /\|\\\/\\\//, '' );
	var url_regexp = new RegExp( '(' + url_protocol + ')' + '(\\w+:{0,1}\\w*@)?(\\S+)(:[0-9]+)?(\/|\/([\\w#!:.?+=&%@!\\-\/]))?' );
	if (fieldVal === "" || url_regexp.test(fieldVal)) {
		return true;
	} else {
		this.addErrorMessage( 'pf_bad_url_error' );
		return false;
	}
};

$.fn.validateEmailField = function() {
	var fieldVal = this.find("input").val();
	// code borrowed from http://javascript.internet.com/forms/email-validation---basic.html
	var email_regexp = /^\s*\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,6})+\s*$/;
	if (fieldVal === '' || email_regexp.test(fieldVal)) {
		return true;
	} else {
		this.addErrorMessage( 'pf_bad_email_error' );
		return false;
	}
};

$.fn.validateNumberField = function() {
	var fieldVal = this.find("input").val();
	// Handle "E notation"/scientific notation ("1.2e-3") in addition
	// to regular numbers
	if (fieldVal === '' ||
	fieldVal.match(/^\s*[\-+]?((\d+[\.,]?\d*)|(\d*[\.,]?\d+))([eE]?[\-\+]?\d+)?\s*$/)) {
		return true;
	} else {
		this.addErrorMessage( 'pf_bad_number_error' );
		return false;
	}
};

$.fn.validateIntegerField = function() {
	var fieldVal = this.find("input").val();
	if ( fieldVal === '' || fieldVal == parseInt( fieldVal, 10 ) ) {
		return true;
	} else {
		this.addErrorMessage( 'pf_bad_integer_error' );
		return false;
	}
};

$.fn.validateDateField = function() {
	// validate only if day and year fields are both filled in
	var dayVal = this.find(".dayInput").val();
	var yearVal = this.find(".yearInput").val();
	if (dayVal === '' || yearVal === '') {
		return true;
	} else if (dayVal.match(/^\d+$/) && dayVal <= 31) {
		// no year validation, since it can also include
		// 'BC' and possibly other non-number strings
		return true;
	} else {
		this.addErrorMessage( 'pf_bad_date_error' );
		return false;
	}
};

// Standalone pipes are not allowed, because they mess up the template
// parsing; unless they're part of a call to a template or a parser function.
$.fn.checkForPipes = function() {
	var fieldVal = this.find("input, textarea").val();
	// We need to check for a few different things because this is
	// called for a variety of different input types.
	if ( fieldVal === undefined || fieldVal === '' ) {
		fieldVal = this.text();
	}
	if ( fieldVal === undefined || fieldVal === '' ) {
		return true;
	}
	if ( fieldVal.indexOf( '|' ) < 0 ) {
		return true;
	}

	// Also allow pipes within special tags, like <pre> or <syntaxhighlight>.
	// Code copied, more or less, from PFTemplateInForm::escapeNonTemplatePipes().
	var startAndEndTags = [
		[ '<pre', 'pre>' ],
		[ '<syntaxhighlight', 'syntaxhighlight>' ],
		[ '<source', 'source>' ],
		[ '<ref', 'ref>' ]
	];

	for ( var i in startAndEndTags ) {
		var startTag = startAndEndTags[i][0];
		var endTag = startAndEndTags[i][1];
		var pattern = RegExp( "(" + startTag + "[^]*?)\\|([^]*?" + endTag + ")", 'i' );
		var matches;
		while ( ( matches = fieldVal.match( pattern ) ) !== null ) {
			// Special handling, to avoid escaping pipes
			// within a string that looks like:
			// startTag ... endTag | startTag ... endTag
			if ( matches[1].includes( endTag ) &&
				matches[2].includes( startTag ) ) {
				fieldVal = fieldVal.replace( pattern, "$1" + "\2" + "$2");
			} else {
				fieldVal = fieldVal.replace( pattern, "$1" + "\1" + "$2" );
			}
		}
	}
	fieldVal = fieldVal.replace( "\2", '|' );

	// Now check for pipes outside of brackets.
	var nextPipe,
		nextDoubleBracketsStart,
		nextDoubleBracketsEnd;

	// There's at least one pipe - here's where the real work begins.
	// We do a mini-parsing of the string to try to make sure that every
	// pipe is within either double square brackets (links) or double
	// curly brackets (parser functions, template calls).
	// For simplicity's sake, turn all curly brackets into square brackets,
	// so we only have to check for one thing.
	// This will incorrectly allow bad text like "[[a|b}}", but hopefully
	// that's not a major problem.
	fieldVal = fieldVal.replace( /{{/g, '[[' );
	fieldVal = fieldVal.replace( /}}/g, ']]' );
	var curIndex = 0;
	var numUnclosedBrackets = 0;
	while ( true ) {
		nextDoubleBracketsStart = fieldVal.indexOf( '[[', curIndex );

		if ( numUnclosedBrackets === 0 ) {
			nextPipe = fieldVal.indexOf( '|', curIndex );
			if ( nextPipe < 0 ) {
				return true;
			}
			if ( nextDoubleBracketsStart < 0 || nextPipe < nextDoubleBracketsStart ) {
				// There's a pipe where it shouldn't be.
				this.addErrorMessage( 'pf_pipe_error' );
				return false;
			}
		} else {
			if ( nextDoubleBracketsEnd < 0 ) {
				// Something is malformed - might as well throw
				// an error.
				this.addErrorMessage( 'pf_pipe_error' );
				return false;
			}
		}

		nextDoubleBracketsEnd = fieldVal.indexOf( ']]', curIndex );

		if ( nextDoubleBracketsStart >= 0 && nextDoubleBracketsStart < nextDoubleBracketsEnd ) {
			numUnclosedBrackets++;
			curIndex = nextDoubleBracketsStart + 2;
		} else {
			numUnclosedBrackets--;
			curIndex = nextDoubleBracketsEnd + 2;
		}
	}

	// We'll never get here, but let's have this line anyway.
	return true;
};

window.validateAll = function () {

	// Hook that fires on form submission, before the validation.
	mw.hook('pf.formValidationBefore').fire();

	var num_errors = 0;

	// Remove all old error messages.
	$(".errorMessage").remove();

	// Make sure all inputs are ignored in the "starter" instance
	// of any multiple-instance template.
	$(".multipleTemplateStarter").find("span, div").addClass("hiddenByPF");

	$(".multipleTemplateList").each( function() {
		if (! $(this).validateNumInstances() ) {
			num_errors += 1;
		}
	});

	$("span.inputSpan.mandatoryFieldSpan").not(".hiddenByPF").each( function() {
		if (! $(this).validateMandatoryField() ) {
			num_errors += 1;
		}
	});
	$("div.ui-widget.mandatory").not(".hiddenByPF").each( function() {
		if (! $(this).validateMandatoryComboBox() ) {
			num_errors += 1;
		}
	});
	$("span.dateInput.mandatoryFieldSpan").not(".hiddenByPF").each( function() {
		if (! $(this).validateMandatoryDateField() ) {
			num_errors += 1;
		}
	});
	$("span.radioButtonSpan.mandatoryFieldSpan").not(".hiddenByPF").each( function() {
		if (! $(this).validateMandatoryRadioButton() ) {
			num_errors += 1;
		}
	});
	$("span.checkboxesSpan.mandatoryFieldSpan").not(".hiddenByPF").each( function() {
		if (! $(this).validateMandatoryCheckboxes() ) {
			num_errors += 1;
		}
	});
	$("div.pfTreeInput.mandatory").not(".hiddenByPF").each( function() {
		// @HACK - handle both the options for tree, checkboxes and
		// radiobuttons, at the same time, regardless of which one is
		// being used. This seems to work fine, though.
		if (! $(this).validateMandatoryCheckboxes() ) {
			num_errors += 1;
		}
		if (! $(this).validateMandatoryRadioButton() ) {
			num_errors += 1;
		}
	});
	$("span.inputSpan.uniqueFieldSpan").not(".hiddenByPF").each( function() {
		if (! $(this).validateUniqueField() ) {
			num_errors += 1;
		}
	});
	$("span.inputSpan, div.pfComboBox").not(".hiddenByPF, .freeText, .pageSection").each( function() {
		if (! $(this).checkForPipes() ) {
			num_errors += 1;
		}
	});
	$("span.URLInput").not(".hiddenByPF").each( function() {
		if (! $(this).validateURLField() ) {
			num_errors += 1;
		}
	});
	$("span.emailInput").not(".hiddenByPF").each( function() {
		if (! $(this).validateEmailField() ) {
			num_errors += 1;
		}
	});
	$("span.numberInput").not(".hiddenByPF").each( function() {
		if (! $(this).validateNumberField() ) {
			num_errors += 1;
		}
	});
	$("span.integerInput").not(".hiddenByPF").each( function() {
		if (! $(this).validateIntegerField() ) {
			num_errors += 1;
		}
	});
	$("span.dateInput").not(".hiddenByPF").each( function() {
		if (! $(this).validateDateField() ) {
			num_errors += 1;
		}
	});
	$("input.modifiedInput").not(".hiddenByPF").each( function() {
		// No separate function needed.
		$(this).parent().addErrorMessage( 'pf_modified_input_error' );
		num_errors += 1;
	});

	// call registered validation functions
	var pfdata = $("#pfForm").data('PageForms');

	if ( pfdata && pfdata.validationFunctions.length > 0 ) { // found data object?

		// for every registered input
		for ( var i = 0; i < pfdata.validationFunctions.length; i++ ) {

			// if input is not part of multipleTemplateStarter
			if ( typeof pfdata.validationFunctions[i] !== 'undefined' &&
				$("#" + pfdata.validationFunctions[i].input).closest(".multipleTemplateStarter").length === 0 &&
				$("#" + pfdata.validationFunctions[i].input).closest(".hiddenByPF").length === 0 ) {

				if (! pfdata.validationFunctions[i].valfunction(
						pfdata.validationFunctions[i].input,
						pfdata.validationFunctions[i].parameters)
					) {
					num_errors += 1;
				}
			}
		}
	}

	if (num_errors > 0) {
		// add error header, if it's not there already
		if ($("#form_error_header").size() === 0) {
			$("#contentSub").append('<div id="form_error_header" class="errorbox" style="font-size: medium"><img src="' + mw.config.get( 'wgPageFormsScriptPath' ) + '/skins/MW-Icon-AlertMark.png" />&nbsp;' + mw.message( 'pf_formerrors_header' ).escaped() + '</div><br clear="both" />');
		}
		scroll(0, 0);
	} else {
		// Disable inputs hidden due to either "show on select" or
		// because they're part of the "starter" div for
		// multiple-instance templates, so that they aren't
		// submitted by the form.
		$('.hiddenByPF').find("input, select, textarea").not(':disabled')
		.prop('disabled', true)
		.addClass('disabledByPF');
		//remove error box if it exists because there are no errors in the form now
		$("#contentSub").find(".errorbox").remove();
	}

	// Hook that fires on form submission, after the validation.
	mw.hook('pf.formValidationAfter').fire();

	return (num_errors === 0);
};

/**
 * Minimize all instances if the total height of all the instances
 * is over 800 pixels - to allow for easier navigation and sorting.
 */
$.fn.possiblyMinimizeAllOpenInstances = function() {
	if ( ! this.hasClass( 'minimizeAll' ) ) {
		return;
	}

	var displayedFieldsWhenMinimized = this.attr('data-displayed-fields-when-minimized');
	var allDisplayedFields = null;
	if ( displayedFieldsWhenMinimized ) {
		allDisplayedFields = displayedFieldsWhenMinimized.split(',').map(function(item) {
			return item.trim().toLowerCase();
		});
	}

	this.find('.multipleTemplateInstance').not('.minimized').each( function() {
		var instance = $(this);
		instance.addClass('minimized');
		var valuesStr = '';
		instance.find( "input[type != 'hidden'][type != 'button'], select, textarea, div.ve-ce-surface" ).each( function() {
			// If the set of fields to be displayed was specified in
			// the form definition, check against that list.
			if ( allDisplayedFields !== null ) {
				var fieldFullName = $(this).attr('name');
				if ( !fieldFullName ) {
					return;
				}
				var matches = fieldFullName.match(/.*\[.*\]\[(.*)\]/);
				var fieldRealName = matches[1].toLowerCase();
				if ( !allDisplayedFields.includes( fieldRealName ) ) {
					return;
				}
			}

			var curVal = $(this).val();
			if ( $(this).hasClass('ve-ce-surface') ) {
				// Special handling for VisualEditor/VEForAll textareas.
				curVal = $(this).text();
			}
			if ( typeof curVal !== 'string' || curVal === '' ) {
				return;
			}
			var inputType = $(this).attr('type');
			if ( inputType === 'checkbox' || inputType === 'radio' ) {
				if ( ! $(this).is(':checked') ) {
					return;
				}
			}
			if ( curVal.length > 70 ) {
				curVal = curVal.substring(0, 70) + "...";
			}
			if ( valuesStr !== '' ) {
				valuesStr += ' &middot; ';
			}
			valuesStr += curVal;
		});
		if ( valuesStr === '' ) {
			valuesStr = '<em>No data</em>';
		}
		instance.find('.instanceMain').fadeOut( "medium", function() {
			instance.find('.instanceRearranger').after('<td class="fieldValuesDisplay">' + valuesStr + '</td>');
		});
	});
};

var num_elements = 0;

/**
 * Functions for multiple-instance templates.
 *
 * @param addAboveCurInstance
 */
$.fn.addInstance = function( addAboveCurInstance ) {
	var wgPageFormsShowOnSelect = mw.config.get( 'wgPageFormsShowOnSelect' );
	var wgPageFormsHeightForMinimizingInstances = mw.config.get( 'wgPageFormsHeightForMinimizingInstances' );
	var wrapper = this.closest(".multipleTemplateWrapper");
	var multipleTemplateList = wrapper.find('.multipleTemplateList');

	// If the nubmer of instances is already at the maximum allowed,
	// exit here.
	if ( multipleTemplateList.isAtMaxInstances() ) {
		return false;
	}

	if ( wgPageFormsHeightForMinimizingInstances >= 0 ) {
		if ( ! multipleTemplateList.hasClass('minimizeAll') &&
			multipleTemplateList.height() >= wgPageFormsHeightForMinimizingInstances ) {
			multipleTemplateList.addClass('minimizeAll');
		}
		if ( multipleTemplateList.hasClass('minimizeAll') ) {
			multipleTemplateList
				.addClass('currentFocus')
				.possiblyMinimizeAllOpenInstances();
		}
	}

	// Global variable.
	num_elements++;

	// Create the new instance
	var new_div = wrapper
		.find(".multipleTemplateStarter")
		.clone()
		.removeClass('multipleTemplateStarter')
		.addClass('multipleTemplateInstance')
		.addClass('multipleTemplate') // backwards compatibility
		.removeAttr("id")
		.fadeTo(0,0)
		.slideDown('fast', function() {
			$(this).fadeTo('fast', 1);
		});

	// Add on a new attribute, "data-origID", representing the ID of all
	// HTML elements that had an ID; and delete the actual ID attribute
	// of any divs and spans (presumably, these exist only for the
	// sake of "show on select"). We do the deletions because no two
	// elements on the page are allowed to have the same ID.
	new_div.find('[id!=""]').attr('data-origID', function() { return this.id; });
	new_div.find('div[id!=""], span[id!=""]').removeAttr('id');

	new_div.find('.hiddenByPF')
	.removeClass('hiddenByPF')

	.find('.disabledByPF')
	.prop('disabled', false)
	.removeClass('disabledByPF');

	// Make internal ID unique for the relevant form elements, and replace
	// the [num] index in the element names with an actual unique index
	new_div.find("input, select, textarea").each(
		function() {
			// Add in a 'b' at the end of the name to reduce the
			// chance of name collision with another field
			if (this.name) {
				var old_name = this.name.replace(/\[num\]/g, '');
				$(this).attr('origName', old_name);
				this.name = this.name.replace(/\[num\]/g, '[' + num_elements + 'b]');
			}

			if (this.id) {

				var old_id = this.id;

				this.id = this.id.replace(/input_/g, 'input_' + num_elements + '_');

				// TODO: Data in wgPageFormsShowOnSelect should probably be stored in
				// $("#pfForm").data('PageForms')
				if ( wgPageFormsShowOnSelect[ old_id ] ) {
					wgPageFormsShowOnSelect[ this.id ] = wgPageFormsShowOnSelect[ old_id ];
				}

				// register initialization and validation methods for new inputs

				var pfdata = $("#pfForm").data('PageForms');
				if ( pfdata ) { // found data object?
					var i;
					if ( pfdata.initFunctions[old_id] ) {

						// For every initialization method for
						// input with id old_id, register the
						// method for the new input.
						for ( i = 0; i < pfdata.initFunctions[old_id].length; i++ ) {

							$(this).PageForms_registerInputInit(
								pfdata.initFunctions[old_id][i].initFunction,
								pfdata.initFunctions[old_id][i].parameters,
								true //do not yet execute
								);
						}
					}

					// For every validation method for the
					// input with ID old_id, register it
					// for the new input.
					for ( i = 0; i < pfdata.validationFunctions.length; i++ ) {

						if ( typeof pfdata.validationFunctions[i] !== 'undefined' &&
							pfdata.validationFunctions[i].input === old_id ) {

							$(this).PageForms_registerInputValidation(
								pfdata.validationFunctions[i].valfunction,
								pfdata.validationFunctions[i].parameters
								);
						}
					}
				}
			}
		}
	);

	new_div.find('a').attr('href', function() {
		return this.href.replace(/input_/g, 'input_' + num_elements + '_');
	});

	new_div.find('span').attr('id', function() {
		return this.id.replace(/span_/g, 'span_' + num_elements + '_');
	});

	// Add the new instance.
	if ( addAboveCurInstance ) {
		new_div.insertBefore(this.closest(".multipleTemplateInstance"));
	} else {
		this.closest(".multipleTemplateWrapper")
			.find(".multipleTemplateList")
			.append(new_div);
	}

	new_div.initializeJSElements(true);

	// Initialize new inputs.
	new_div.find("input, select, textarea").each(
		function() {

			if (this.id) {

				var pfdata = $("#pfForm").data('PageForms');
				if ( pfdata ) {

					// have to store data array: the id attribute
					// of 'this' might be changed in the init function
					var thatData = pfdata.initFunctions[this.id] ;

					if ( thatData ) { // if anything registered at all
						// Call every initialization method
						// for this input
						for ( var i = 0; i < thatData.length; i++ ) {
							var initFunction = thatData[i].initFunction;
							if ( initFunction === undefined ) {
								continue;
							}
							// If the code attempted to store
							// this function before it was
							// defined, only its name was stored.
							// In that case, get the function now.
							// @TODO - move getFunctionFromName()
							// so that it can be called from here,
							// which would be better than window[].
							if ( typeof initFunction === 'string' ) {
								initFunction = window[initFunction];
							}
							initFunction(
								this.id,
								thatData[i].parameters
							);
						}
					}
				}
			}
		}
	);

	// Hook that fires each time a new template instance is added.
	// The first parameter is a jQuery selection of the newly created instance div.
	mw.hook('pf.addTemplateInstance').fire(new_div);
};

// The first argument is needed, even though it's an attribute of the element
// on which this function is called, because it's the 'name' attribute for
// regular inputs, and the 'origName' attribute for inputs in multiple-instance
// templates.
$.fn.setDependentAutocompletion = function( dependentField, baseField, baseValue ) {
	// Get data from either Cargo or Semantic MediaWiki.
	var myServer = mw.config.get( 'wgScriptPath' ) + "/api.php",
		wgPageFormsCargoFields = mw.config.get( 'wgPageFormsCargoFields' ),
		wgPageFormsFieldProperties = mw.config.get( 'wgPageFormsFieldProperties' );
	myServer += "?action=pfautocomplete&format=json";
	if ( wgPageFormsCargoFields.hasOwnProperty( dependentField ) ) {
		var cargoTableAndFieldStr = wgPageFormsCargoFields[dependentField];
		var cargoTableAndField = cargoTableAndFieldStr.split('|');
		var cargoTable = cargoTableAndField[0];
		var cargoField = cargoTableAndField[1];
		var baseCargoTableAndFieldStr = wgPageFormsCargoFields[baseField];
		var baseCargoTableAndField = baseCargoTableAndFieldStr.split('|');
		var baseCargoTable = baseCargoTableAndField[0];
		var baseCargoField = baseCargoTableAndField[1];
		myServer += "&cargo_table=" + cargoTable + "&cargo_field=" + cargoField + "&is_array=true" + "&base_cargo_table=" + baseCargoTable + "&base_cargo_field=" + baseCargoField + "&basevalue=" + baseValue;
	} else {
		var propName = wgPageFormsFieldProperties[dependentField];
		var baseProp = wgPageFormsFieldProperties[baseField];
		myServer += "&property=" + propName + "&baseprop=" + baseProp + "&basevalue=" + baseValue;
	}
	var dependentValues = [];
	var thisInput = $(this);
	// We use $.ajax() here instead of $.getJSON() so that the
	// 'async' parameter can be set. That, in turn, is set because
	// if the 2nd, "dependent" field is a combo box, it can have weird
	// behavior: clicking on the down arrow for the combo box leads to a
	// "blur" event for the base field, which causes the possible
	// values to get recalculated, but not in time for the dropdown to
	// change values - it still shows the old values. By setting
	// "async: false", we guarantee that old values won't be shown - if
	// the values haven't been recalculated yet, the dropdown won't
	// appear at all.
	// @TODO - handle this the right way, by having special behavior for
	// the dropdown - it should get delayed until the values are
	// calculated, then appear.
	$.ajax({
		url: myServer,
		dataType: 'json',
		async: false,
		success: function(data) {
			var realData = data.pfautocomplete;
			$.each(realData, function(key, val) {
				dependentValues.push(val.title);
			});
			thisInput.data('autocompletevalues', dependentValues);
			thisInput.attachAutocomplete();
		}
	});
};

/**
 * Called on a 'base' field (e.g., for a country) - sets the autocompletion
 * for its 'dependent' field (e.g., for a city).
 *
 * @param partOfMultiple
 */
$.fn.setAutocompleteForDependentField = function( partOfMultiple ) {
	var curValue = $(this).val();
	if ( curValue === null ) { return this; }

	var nameAttr = partOfMultiple ? 'origName' : 'name';
	var name = $(this).attr(nameAttr);
	var wgPageFormsDependentFields = mw.config.get( 'wgPageFormsDependentFields' );
	var dependent_on_me = [];
	for ( var i = 0; i < wgPageFormsDependentFields.length; i++ ) {
		var dependentFieldPair = wgPageFormsDependentFields[i];
		if ( dependentFieldPair[0] === name ) {
			dependent_on_me.push(dependentFieldPair[1]);
		}
	}
	// @TODO - change to $.uniqueSort() once support for MW 1.28 is
	// removed (and jQuery >= 3 is thus guaranteed).
	dependent_on_me = $.unique(dependent_on_me);

	var self = this;
	$.each( dependent_on_me, function() {
		var element, cmbox, tokens,
			dependentField = this;

		if ( partOfMultiple ) {
			element = $( self ).closest( '.multipleTemplateInstance' )
				.find('[origName="' + dependentField + '"]');
		} else {
			element = $('[name="' + dependentField + '"]');
		}

		if ( element.hasClass( 'pfComboBox' ) ) {
			cmbox = new pf.select2.combobox();
			cmbox.refresh(element);
		} else if ( element.hasClass( 'pfTokens' ) ) {
			tokens = new pf.select2.tokens();
			tokens.refresh(element);
		} else {
			element.setDependentAutocompletion(dependentField, name, curValue);
		}
	});


	return this;
};

/**
 * Initialize all the JS-using elements contained within this block - can be
 * called for either the entire HTML body, or for a div representing an
 * instance of a multiple-instance template.
 *
 * @param partOfMultiple
 */
$.fn.initializeJSElements = function( partOfMultiple ) {
	var fancyBoxSettings;

	this.find(".pfShowIfSelected").each( function() {
		// Avoid duplicate calls on any one element.
		if ( !partOfMultiple && $(this).parents('.multipleTemplateWrapper').length > 0 ) {
			return;
		}
		$(this)
		.showIfSelected(partOfMultiple, true)
		.change( function() {
			$(this).showIfSelected(partOfMultiple, false);
		});
	});

	this.find(".pfShowIfChecked").each( function() {
		// Avoid duplicate calls on any one element.
		if ( !partOfMultiple && $(this).parents('.multipleTemplateWrapper').length > 0 ) {
			return;
		}
		$(this)
		.showIfChecked(partOfMultiple, true)
		.click( function() {
			$(this).showIfChecked(partOfMultiple, false);
		});
	});

	this.find(".pfShowIfCheckedCheckbox").each( function() {
		// Avoid duplicate calls on any one element.
		if ( !partOfMultiple && $(this).parents('.multipleTemplateWrapper').length > 0 ) {
			return;
		}
		$(this)
		.showIfCheckedCheckbox(partOfMultiple, true)
		.click( function() {
			$(this).showIfCheckedCheckbox(partOfMultiple, false);
		});
	});

	if ( partOfMultiple ) {
		// Enable the new remove button
		this.find(".removeButton").click( function() {

			// Unregister initialization and validation for deleted inputs
			$(this).parentsUntil( '.multipleTemplateInstance' ).last().parent().find("input, select, textarea").each(
			function() {
				$(this).PageForms_unregisterInputInit();
				$(this).PageForms_unregisterInputValidation();
			}
		);

			// Remove the encompassing div for this instance.
			$(this).closest(".multipleTemplateInstance")
			.fadeTo('fast', 0, function() {
				$(this).slideUp('fast', function() {
					$(this).remove();
				});
			});
			return false;
		});

		// ...and the new adder
		this.find('.addAboveButton').click( function() {
			$(this).addInstance( true );
			return false; // needed to disable <a> behavior
		});
	}

	var combobox = new pf.select2.combobox();
	this.find('.pfComboBox').not('#semantic_property_starter, .multipleTemplateStarter .pfComboBox, .select2-container').each( function() {
		combobox.apply($(this));
	});

	var tokens = new pf.select2.tokens();
	this.find('.pfTokens').not('.multipleTemplateStarter .pfTokens, .select2-container').each( function() {
		tokens.apply($(this));
	});

	// We use a different version of FancyBox depending on the version
	// of jQuery (1 vs. 3) (which in turn depends on the version of
	// MediaWiki (<= 1.29 vs. >= 1.30)).
	if ( parseInt($().jquery) >= 3 ) {
		fancyBoxSettings = {
			toolbar : false,
			smallBtn : true,
			iframe : {
				preload : false,
				css : {
					width : '75%',
					height : '75%'
				}
			},
			animationEffect : false
		};
	} else {
		fancyBoxSettings = {
			'width'         : '75%',
			'height'        : '75%',
			'autoScale'     : false,
			'transitionIn'  : 'none',
			'transitionOut' : 'none',
			'type'          : 'iframe',
			'overlayColor'  : '#222',
			'overlayOpacity' : '0.8'
		};
	}

	// Only defined if $wgPageFormsSimpleUpload == true.
	if ( typeof this.initializeSimpleUpload === 'function' ) {
		this.initializeSimpleUpload();
	}

	if ( partOfMultiple ) {
		this.find('.pfFancyBox').fancybox(fancyBoxSettings);
		this.find('.autocompleteInput').attachAutocomplete();
		this.find('.autoGrow').autoGrow();
		this.find(".pfRating").applyRatingInput();
		this.find(".pfTreeInput").each( function() {
			$(this).applyFancytree();
		});
	} else {
		this.find('.pfFancyBox').not('multipleTemplateWrapper .pfFancyBox').fancybox(fancyBoxSettings);
		this.find('.autocompleteInput').not('.multipleTemplateWrapper .autocompleteInput').attachAutocomplete();
		this.find('.autoGrow').not('.multipleTemplateWrapper .autoGrow').autoGrow();
		this.find(".pfRating").not(".multipleTemplateWrapper .pfRating").applyRatingInput();
		this.find(".pfTreeInput").not(".multipleTemplateWrapper .pfTreeInput").each( function() {
			$(this).applyFancytree();
		});
	}

	// @TODO - this should ideally be called only for inputs that have
	// a dependent field - which might involve changing the storage of
	// "dependent fields" information from a global variable to a
	// per-input HTML attribute.
	this.find('input, select').each( function() {
		$(this)
		.setAutocompleteForDependentField( partOfMultiple )
		.blur( function() {
			$(this).setAutocompleteForDependentField( partOfMultiple );
		});
	});
	// The 'blur' event doesn't get triggered for radio buttons for
	// Chrome and Safari (the WebKit-based browsers) so use the 'change'
	// event in addition.
	// @TODO - blur() shuldn't be called at all for radio buttons.
	this.find('input:radio')
		.change( function() {
			$(this).setAutocompleteForDependentField( partOfMultiple );
		});

	var myThis = this;
	if ( $.fn.applyVisualEditor ) {
		if ( partOfMultiple ) {
			myThis.find(".visualeditor").applyVisualEditor();
		} else {
			myThis.find(".visualeditor").not(".multipleTemplateWrapper .visualeditor").applyVisualEditor();
		}
	} else {
		$(document).on('VEForAllLoaded', function(e) {
			if ( partOfMultiple ) {
				myThis.find(".visualeditor").applyVisualEditor();
			} else {
				myThis.find(".visualeditor").not(".multipleTemplateWrapper .visualeditor").applyVisualEditor();
			}
		});
	}

	// @TODO - this should be in the TinyMCE extension, and use a hook.
	if ( typeof( mwTinyMCEInit ) === 'function' ) {
		if ( partOfMultiple ) {
			myThis.find(".tinymce").each( function() {
				mwTinyMCEInit( '#' + $(this).attr('id') );
			});
		} else {
			myThis.find(".tinymce").not(".multipleTemplateWrapper .tinymce").each( function() {
				mwTinyMCEInit( '#' + $(this).attr('id') );
			});
		}
	} else {
		$(document).on('TinyMCELoaded', function(e) {
			if ( partOfMultiple ) {
				myThis.find(".tinymce").each( function() {
					mwTinyMCEInit( '#' + $(this).attr('id') );
				});
			} else {
				myThis.find(".tinymce").not(".multipleTemplateWrapper .tinymce").each( function() {
					mwTinyMCEInit( '#' + $(this).attr('id') );
				});
			}
		});
	}

};

// Once the document has finished loading, set up everything!
$(document).ready( function() {
	var i,
		inputID,
		validationFunctionData;

	function getFunctionFromName( functionName ) {
		var func = window;
		var namespaces = functionName.split( "." );
		for ( var i = 0; i < namespaces.length; i++ ) {
			func = func[ namespaces[ i ] ];
		}
		// If this gets called before the function is defined, just
		// store the function name instead, for later lookup.
		if ( func === null ) {
			return functionName;
		}
		return func;
	}

	// Initialize inputs created by #forminput.
	if ( $('.pfFormInput').length > 0 ) {
		$('.autocompleteInput').attachAutocomplete();
	}

	// Exit now if a Page Forms form is not present.
	if ( $('#pfForm').length === 0 ) {
		return;
	}

	// jQuery's .ready() function is being called before the resource was actually loaded.
	// This is a workaround for https://phabricator.wikimedia.org/T216805.
	setTimeout( function(){
		// "Mask" to prevent users from clicking while form is still loading.
		$('#loadingMask').css({'width': $(document).width(),'height': $(document).height()});

		// register init functions
		var initFunctionData = mw.config.get( 'ext.pf.initFunctionData' );
		for ( inputID in initFunctionData ) {
			for ( i in initFunctionData[inputID] ) {
				/*jshint -W069 */
				$( '#' + inputID ).PageForms_registerInputInit( getFunctionFromName( initFunctionData[ inputID ][ i ][ 'name' ] ), initFunctionData[ inputID ][ i ][ 'param' ] );
				/*jshint +W069 */
			}
		}

		// register validation functions
		validationFunctionData = mw.config.get( 'ext.pf.validationFunctionData' );
		for ( inputID in validationFunctionData ) {
			for ( i in validationFunctionData[inputID] ) {
				/*jshint -W069 */
				$( '#' + inputID ).PageForms_registerInputValidation( getFunctionFromName( validationFunctionData[ inputID ][ i ][ 'name' ] ), validationFunctionData[ inputID ][ i ][ 'param' ] );
				/*jshint +W069 */
			}
		}

		$( 'body' ).initializeJSElements(false);

		$('.multipleTemplateInstance').initializeJSElements(true);
		$('.multipleTemplateAdder').click( function() {
			$(this).addInstance( false );
		});
		var wgPageFormsHeightForMinimizingInstances = mw.config.get( 'wgPageFormsHeightForMinimizingInstances' );
		if ( wgPageFormsHeightForMinimizingInstances >= 0) {
			$('.multipleTemplateList').each( function() {
				if ( $(this).height() > wgPageFormsHeightForMinimizingInstances ) {
					$(this).addClass('minimizeAll');
					$(this).possiblyMinimizeAllOpenInstances();
				}
			});
		}
		$('.multipleTemplateList').each( function() {
			var list = $(this);
			var sortable = Sortable.create(list[0], {
				handle: '.instanceRearranger',
				onStart: function (/**Event*/evt) {
					list.possiblyMinimizeAllOpenInstances();
				}
			});
		});

		// If the form is submitted, validate everything!
		$('#pfForm').submit( function() {
			return validateAll();
		} );

		// We are all done - remove the loading spinner.
		$('.loadingImage').remove();
	}, 0 );

	mw.hook('pf.formSetupAfter').fire();
});

// If some part of the form is clicked, minimize any multiple-instance
// template instances that need minimizing, and move the "focus" to the current
// instance list, if one is being clicked and it's different from the
// previous one.
// We make only the form itself clickable, instead of the whole screen, to
// try to avoid a click on a popup, like the "Upload file" window, minimizing
// the current open instance.
$('form#pfForm').click( function(e) {
	var target = $(e.target);
	// Ignore the "add instance" buttons - those get handling of their own.
	if ( target.hasClass('multipleTemplateAdder') || target.hasClass('addAboveButton') ) {
		return;
	}

	var instance = target.closest('.multipleTemplateInstance');
	if ( instance === null ) {
		$('.multipleTemplateList.currentFocus')
			.removeClass('currentFocus')
			.possiblyMinimizeAllOpenInstances();
		return;
	}

	var instancesList = instance.closest('.multipleTemplateList');
	if ( !instancesList.hasClass('currentFocus') ) {
		$('.multipleTemplateList.currentFocus')
			.removeClass('currentFocus')
			.possiblyMinimizeAllOpenInstances();
		if ( instancesList.hasClass('minimizeAll') ) {
			instancesList.addClass('currentFocus');
		}
	}

	if ( instance.hasClass('minimized') ) {
		instancesList.possiblyMinimizeAllOpenInstances();
		instance.removeClass('minimized');
		instance.find('.fieldValuesDisplay').html('');
		instance.find('.instanceMain').fadeIn();
		instance.find('.fieldValuesDisplay').remove();
	}
});

$('#pf-expand-all a').click(function( event ) {
	event.preventDefault();

	// Page Forms minimized template instances.
	$('.minimized').each( function() {
		$(this).removeClass('minimized');
		$(this).find('.fieldValuesDisplay').html('');
		$(this).find('.instanceMain').fadeIn();
		$(this).find('.fieldValuesDisplay').remove();
        });

	// Standard MediaWiki "collapsible" sections.
	$('div.mw-collapsed a.mw-collapsible-text').click();
});

}( jQuery, mediaWiki ) );
