<?php

namespace SMW\Query\Processor;

use SMW\Query\PrintRequestFactory;

/**
 * @private
 *
 * @license GPL-2.0-or-later
 * @since 3.0
 *
 * @author mwjames
 */
class ParamListProcessor {

	/**
	 * Format type
	 */
	const FORMAT_LEGACY = 'format.legacy';

	/**
	 * Identify the PrintThis instance
	 */
	const PRINT_THIS = 'print.this';

	/**
	 * @var PrintRequestFactory
	 */
	private $printRequestFactory;

	/**
	 * @since 3.0
	 *
	 * @param PrintRequestFactory|null $printRequestFactory
	 */
	public function __construct( ?PrintRequestFactory $printRequestFactory = null ) {
		$this->printRequestFactory = $printRequestFactory;

		if ( $this->printRequestFactory === null ) {
			$this->printRequestFactory = new PrintRequestFactory();
		}
	}

	/**
	 * @since 3.0
	 *
	 * @param array $paramList
	 * @param string $type
	 *
	 * @return array
	 */
	public function format( array $paramList, $type ) {
		if ( $type === self::FORMAT_LEGACY ) {
			return $this->legacy_format( $paramList );
		}

		return $paramList;
	}

	/**
	 * @since 3.0
	 *
	 * @param array $parameters
	 * @param bool $showMode
	 *
	 * @return array
	 */
	public function preprocess( array $parameters, $showMode = false ) {
		$previousPrintout = null;

		$serialization = [
			'showMode'   => $showMode,
			'templateArgs' => false,
			'query'      => '',
			'this'       => [],
			'printouts'  => [],
			'parameters' => []
		];

		foreach ( $parameters as $key => $value ) {
			if ( !is_array( $value ) && $value !== null && ( str_contains( $value, '+width' ) || str_contains( $value, '+height' ) ) ) {
				$this->handleWidthHeightParameters( $parameters );
				break;
			}
		}

		foreach ( $parameters as $name => $param ) {
			// special handling for arrays - this can happen if the
			// parameter came from a checkboxes input in Special:Ask:
			if ( is_array( $param ) ) {
				$param = implode( ',', array_keys( $param ) );
			}

			$param = $this->encodeEq( $param );
			if ( $param === null ) {
				continue;
			}

			// #1258 (named_args -> named args)
			// accept 'name' => 'value' just as '' => 'name=value':
			if ( is_string( $name ) && ( $name !== '' ) ) {
				$param = str_replace( "_", " ", $name ) . '=' . $param;
			}

			// Find out whether this is a mainlabel, and if so store related
			// parameters separate since QueryProcessor::addThisPrintout is
			// added in isolation !!??!!
			// $isMainlabel = strpos( $param, 'mainlabel=' ) !== false;

			// mainlable=Foo=|+width=40px - is now supportable
			// use
			// |?=Foo=|+width=40px|+link= ...
			// |mainlabel=-
			$isMainlabel = false;

			if ( $param === '' ) {
			} elseif ( $isMainlabel ) {
				$this->addThisPrintRequest( $name, $param, $previousPrintout, $serialization );
			} elseif ( $param[0] == '?' ) {
				$this->addPrintRequest( $name, $param, $previousPrintout, $serialization );
			} elseif ( str_contains( $param, '+width=' ) || str_contains( $param, '+height=' ) ) {
				$sizeFormatter = new SizeFormatterOption();
				$result = $sizeFormatter->getPrintRequestWithOutputMarker( $param, $previousPrintout, $serialization );
				$serialization = $result[ 'serialization' ];
			} elseif ( str_contains( $param, '+link=' ) ) {
				$linkFormatter = new LinkFormatterOption();
				$result = $linkFormatter->getPrintRequestWithOutputMarker( $param, $previousPrintout, $serialization );
				$serialization = $result[ 'serialization' ];
				$labelPreviousPrintout = $serialization[ 'printouts' ][ $previousPrintout ][ 'label' ];
			} elseif ( str_contains( $param, '+thclass=' ) ) {
				$headerFormatter = new TableHeaderFormatterOption();
				$result = $headerFormatter->getPrintRequestWithOutputMarker( $param, $previousPrintout, $serialization );
				$serialization = $result[ 'serialization' ];
				$labelPreviousPrintout = $serialization[ 'printouts' ][ $previousPrintout ][ 'label' ];
			} elseif ( $param[0] == '+' && ( !str_contains( $param, '+link=' ) && !str_contains( $param, '+thclass=' ) &&
				!str_contains( $param, '+width=' ) && !str_contains( $param, '+height=' ) ) ) {
				$this->addPrintRequestParameter( $name, $param, $previousPrintout, $serialization );
			} else {
				$this->addOtherParameters( $name, $param, $serialization, $showMode );
			}
		}

		$serialization['query'] = str_replace(
			[ '&lt;', '&gt;', '0x003D' ],
			[ '<', '>', '=' ],
			$serialization['query']
		);

		if ( $showMode ) {
			$serialization['query'] = '[[:' . $serialization['query'] . ']]';
		}

		return $serialization;
	}

	/**
	 * Handles width and height parameters in the given array of parameters.
	 * It looks for parameters starting with '+width=' and '+height=',
	 * temporarily removes them from the array, and appends them
	 * after the specific '?' parameter in the array.
	 *
	 * This function modifies the input parameters array by reference,
	 * so no return value is needed.
	 *
	 * @param array &$parameters The array of parameters to process.
	 */
	private function handleWidthHeightParameters( array &$parameters ) {
		$pendingWidth = null;
		$pendingHeight = null;
		$lastFieldIndex = null;

		foreach ( $parameters as $index => &$param ) {
			// Check for width and height definitions
			if ( strpos( $param, '+width=' ) !== false ) {
				$pendingWidth = $param;
				unset( $parameters[ $index ] );
			} elseif ( strpos( $param, '+height=' ) !== false ) {
				$pendingHeight = $param;
				unset( $parameters[ $index ] );
			} elseif ( strpos( $param, '?' ) === 0 ) {
				// For each ?parameter, track its index
				$lastFieldIndex = $index;
			}

			// After processing the ?parameter, append width and height if pending
			if ( $lastFieldIndex !== null && ( $pendingWidth || $pendingHeight ) ) {
				if ( $pendingWidth ) {
					array_splice( $parameters, $lastFieldIndex + 1, 0, $pendingWidth );
					$pendingWidth = null;
					$lastFieldIndex++;
				}
				if ( $pendingHeight ) {
					array_splice( $parameters, $lastFieldIndex + 1, 0, $pendingHeight );
					$pendingHeight = null;
					$lastFieldIndex++;
				}
			}
		}
		// Re-index the array to reset the keys
		$parameters = array_values( $parameters );
	}

	private function legacy_format( array $paramList ) {
		$printouts = [];

		foreach ( $paramList['printouts'] as $k => $request ) {

			if ( !isset( $request['label'] ) ) {
				continue;
			}

			// #502
			// In case of template arguments suppress the showMode to allow for
			// labels to be generated and to be transfered to the invoked template
			// otherwise labels will be empty and not be accessible in a template
			$showMode = $paramList['templateArgs'] ? false : $paramList['showMode'];

			// #3548
			// Use a canonical label when referenced as part of a template to ensure
			// that labels (such as a preferred label) don't change with a language
			// setting
			$asCanonicalLabel = $paramList['templateArgs'];

			$printRequest = $this->printRequestFactory->newFromText(
				$request['label'],
				$showMode,
				$asCanonicalLabel
			);

			if ( $printRequest === null ) {
				continue;
			}

			foreach ( $request['params'] as $key => $value ) {
					$printRequest->setParameter( $key, $value );
			}

			// get outputFormat for each ?property and update params like thclass and link
			$outputFormat = $printRequest->getOutputFormat();

			if ( str_contains( $outputFormat, 'thclass' ) ) {
				$outputFormat = str_replace( 'thclass', 'class=' . $request['params']['thclass'], $outputFormat );
			}
			if ( str_contains( $outputFormat, 'link' ) ) {
				$outputFormat = str_replace( 'link', 'link=' . $request['params']['link'], $outputFormat );
			}

			// set updated outputFormat for each ?property
			$printRequest->setOutputFormat( $outputFormat );
			$printouts[] = $printRequest;
		}

		return [
			$paramList['query'],
			$paramList['parameters'],
			$printouts
		];
	}

	private function encodeEq( $param ) {
		// Bug 32955 / #640
		// Modify (e.g. replace `=`) a condition string only if enclosed by
		// [[ ... ]]
		//
		// #3560
		// Instead of `-3D` as temporary replacement, use the UTF representation
		// to decode the `=` sign and eliminate possible collisions with a search
		// request that contains `-3D` string
		return preg_replace_callback(
			'/\[\[([^\[\]]*)\]\]/xu',
			static function ( array $matches ) {
				return str_replace( [ '=' ], [ '0x003D' ], $matches[0] );
			},
			$param ?? ''
		);
	}

	private function addPrintRequest( $name, $param, &$previousPrintout, array &$serialization ) {
		$param = substr( $param, 1 );

		// Currently we don't filter any duplicates hence the additional
		// $name is added to distinguish printouts with the same configuration
		$hash = md5( json_encode( $param ) . $name );
		$previousPrintout = $hash;

		$serialization['printouts'][$hash] = [
			'label' => $param,
			'params' => []
		];
	}

	private function addThisPrintRequest( $name, $param, &$previousPrintout, array &$serialization ) {
		$param = substr( $param, 1 );

		$parts = explode( '=', $param, 2 );
		$serialization['parameters']['mainlabel'] = count( $parts ) >= 2 ? $parts[1] : null;
		$previousPrintout = self::PRINT_THIS;
	}

	private function addPrintRequestParameter( $name, $param, $previousPrintout, array &$serialization ) {
		if ( $previousPrintout === null ) {
			return;
		}

		$param = substr( $param, 1 );
		$parts = explode( '=', $param, 2 );

		if ( $previousPrintout === self::PRINT_THIS ) {
			if ( count( $parts ) == 2 ) {
				$serialization['this'] = [ trim( $parts[0] ) => $parts[1] ];
			} else {
				$serialization['this'] = [ trim( $parts[0] ) => null ];
			}
		} else {
			if ( count( $parts ) == 2 ) {
				$serialization['printouts'][$previousPrintout]['params'][trim( $parts[0] )] = $parts[1];
			} else {
				$serialization['printouts'][$previousPrintout]['params'][trim( $parts[0] )] = null;
			}
		}
	}

	private function addOtherParameters( $name, $param, array &$serialization, $showMode ) {
		// #1645
		$parts = $showMode && $name == 0 ? $param : explode( '=', $param, 2 );

		if ( is_array( $parts ) && count( $parts ) >= 2 ) {
			$p = strtolower( trim( $parts[0] ) );

			if ( $p === 'template' ) {
				$serialization['templateArgs'] = true;
			}

			// Don't trim here, some parameters care for " "
			//
			// #3196
			// Ensure to decode `0x003D` from encodeEq to support things like
			// `|intro=[[File:Foo.png|link=Bar]]`
			$serialization['parameters'][$p] = str_replace( [ '0x003D' ], [ '=' ], $parts[1] );
		} else {
			$serialization['query'] .= $param;
		}
	}
}
