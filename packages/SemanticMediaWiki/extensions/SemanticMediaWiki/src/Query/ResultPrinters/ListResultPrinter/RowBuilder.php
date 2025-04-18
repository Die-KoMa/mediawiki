<?php

namespace SMW\Query\ResultPrinters\ListResultPrinter;

/**
 * Class RowBuilder
 *
 * @license GPL-2.0-or-later
 * @since 3.0
 *
 * @author Stephan Gambke
 */
abstract class RowBuilder {

	use ParameterDictionaryUser;

	private $valueTextsBuilder;

	/**
	 * @param \SMW\Query\Result\ResultArray[] $fields
	 *
	 * @param int $rownum
	 *
	 * @return string
	 */
	abstract public function getRowText( array $fields, $rownum = 0 );

	/**
	 * @return mixed
	 */
	protected function getValueTextsBuilder() {
		return $this->valueTextsBuilder;
	}

	/**
	 * @param mixed $valueTextsBuilder
	 */
	public function setValueTextsBuilder( $valueTextsBuilder ) {
		$this->valueTextsBuilder = $valueTextsBuilder;
	}

}
