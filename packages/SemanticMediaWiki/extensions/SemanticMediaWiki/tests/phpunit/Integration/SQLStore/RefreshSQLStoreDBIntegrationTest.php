<?php

namespace SMW\Tests\Integration\SQLStore;

use SMW\Tests\SMWIntegrationTestCase;
use SMW\Tests\Utils\MwHooksHandler;
use SMW\Tests\Utils\PageCreator;
use SMW\Tests\Utils\PageDeleter;
use Title;

/**
 *
 * @group SMW
 * @group SMWExtension
 * @group semantic-mediawiki-integration
 * @group mediawiki-database
 * @group Database
 * @group medium
 *
 * @license GPL-2.0-or-later
 * @since 1.9
 *
 * @author mwjames
 */
class RefreshSQLStoreDBIntegrationTest extends SMWIntegrationTestCase {

	private $title;
	private $mwHooksHandler;
	private $pageDeleter;
	private $pageCreator;

	protected function setUp(): void {
		parent::setUp();

		$this->mwHooksHandler = new MwHooksHandler();
		$this->pageDeleter = new PageDeleter();
		$this->pageCreator = new PageCreator();
	}

	public function tearDown(): void {
		$this->mwHooksHandler->restoreListedHooks();

		if ( $this->title !== null ) {
			$this->pageDeleter->deletePage( $this->title );
		}

		parent::tearDown();
	}

	/**
	 * @dataProvider titleProvider
	 */
	public function testAfterPageCreation_StoreHasDataToRefreshWithoutJobs( $ns, $name, $iw ) {
		$this->mwHooksHandler->deregisterListedHooks();

		$this->title = Title::makeTitle( $ns, $name, '', $iw );

		$this->pageCreator->createPage( $this->title );

		$this->assertStoreHasDataToRefresh( false );
	}

	/**
	 * @dataProvider titleProvider
	 */
	public function testAfterPageCreation_StoreHasDataToRefreshWitJobs( $ns, $name, $iw ) {
		$this->mwHooksHandler->deregisterListedHooks();

		$this->title = Title::makeTitle( $ns, $name, '', $iw );

		$this->pageCreator->createPage( $this->title );

		$this->assertStoreHasDataToRefresh( true );
	}

	protected function assertStoreHasDataToRefresh( $useJobs ) {
		$refreshPosition = $this->title->getArticleID();

		$entityRebuildDispatcher = $this->getStore()->refreshData(
			$refreshPosition,
			1,
			false,
			$useJobs
		);

		$entityRebuildDispatcher->rebuild( $refreshPosition );

		$this->assertGreaterThan(
			0,
			$entityRebuildDispatcher->getEstimatedProgress()
		);
	}

	public function titleProvider() {
		$provider = [];

	// $provider[] = array( NS_MAIN, 'withInterWiki', 'commons' );
		$provider[] = [ NS_MAIN, 'NormalTite', '' ];
		$provider[] = [ NS_MAIN, 'UseUpdateJobs', '' ];

		return $provider;
	}

}
