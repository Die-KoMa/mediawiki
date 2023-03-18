<?php

namespace SMW\MediaWiki;

use Title;

/**
 * @license GNU GPL v2+
 * @since 2.0
 *
 * @author mwjames
 */
class TitleFactory {

	/**
	 * @since  2.0
	 *
	 * @param  string $text
	 *
	 * @return Title|null
	 */
	public function newFromText( $text, $namespace = null ) {

		if ( $namespace === null ) {
			$namespace = NS_MAIN;
		}

		return Title::newFromText( $text, $namespace );
	}

	/**
	 * @since 3.0
	 *
	 * @param integer $id
	 *
	 * @return Title|null
	 */
	public function newFromID( $id ) {
		return Title::newFromID( $id );
	}

	/**
	 * @since 3.0
	 *
	 * @param array $ids
	 *
	 * @return Title[]
	 */
	public function newFromIDs( $ids ) {
		return Title::newFromIDs( $ids );
	}
	/**
	 * @since 3.0
	 *
	 * @param int $ns
	 * @param string $title
	 * @param string $fragment
	 * @param string $interwiki
	 *
	 * @return Title|null
	 */
	public function makeTitleSafe( $ns, $title, $fragment = '', $interwiki = '' ) {
		return Title::makeTitleSafe( $ns, $title, $fragment, $interwiki );
	}

}
