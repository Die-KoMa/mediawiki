<?php

namespace SMW\Tests\Exporter\Element;

use SMW\DIWikiPage;
use SMW\Exporter\Element\ExpElement;
use SMW\Exporter\Element\ExpLiteral;
use SMW\Tests\PHPUnitCompat;
use SMWDataItem as DataItem;

/**
 * @covers \SMW\Exporter\Element\ExpLiteral
 * @group semantic-mediawiki
 *
 * @license GPL-2.0-or-later
 * @since 2.2
 *
 * @author mwjames
 */
class ExpLiteralTest extends \PHPUnit\Framework\TestCase {

	use PHPUnitCompat;

	public function testCanConstruct() {
		$this->assertInstanceOf(
			'\SMW\Exporter\Element\ExpLiteral',
			new ExpLiteral( '', '', '', null )
		);
	}

	/**
	 * @dataProvider constructorProvider
	 */
	public function testAccessToMethods( $lexicalForm, $datatype, $lang, $dataItem ) {
		$instance = new ExpLiteral(
			$lexicalForm,
			$datatype,
			$lang,
			$dataItem
		);

		$this->assertEquals(
			$datatype,
			$instance->getDatatype()
		);

		$this->assertEquals(
			$lang,
			$instance->getLang()
		);

		$this->assertEquals(
			$lexicalForm,
			$instance->getLexicalForm()
		);

		$this->assertEquals(
			$dataItem,
			$instance->getDataItem()
		);
	}

	/**
	 * @dataProvider constructorProvider
	 */
	public function testSerializiation( $lexicalForm, $datatype, $lang, $dataItem, $expected ) {
		$instance = new ExpLiteral(
			$lexicalForm,
			$datatype,
			$lang,
			$dataItem
		);

		$this->assertEquals(
			$expected,
			$instance->getSerialization()
		);

		$this->assertEquals(
			$instance,
			ExpElement::newFromSerialization( $instance->getSerialization() )
		);
	}

	/**
	 * @dataProvider invalidConstructorProvider
	 */
	public function testInvalidConstructorThrowsException( $lexicalForm, $datatype, $lang, $dataItem ) {
		$this->expectException( 'InvalidArgumentException' );

		$instance = new ExpLiteral(
			$lexicalForm,
			$datatype,
			$lang,
			$dataItem
		);
	}

	/**
	 * @dataProvider serializationMissingElementProvider
	 */
	public function testDeserializiationForMissingElementThrowsException( $serialization ) {
		$this->expectException( 'RuntimeException' );

		ExpElement::newFromSerialization(
			$serialization
		);
	}

	public function constructorProvider() {
		# 0
		$provider[] = [
			'', '', '', null,
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'  => '',
				'datatype'  => '',
				'lang'  => '',
				'dataitem' => null
			]
		];

		# 1
		$provider[] = [
			'Foo', '', '', null,
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'  => 'Foo',
				'datatype' => '',
				'lang'     => '',
				'dataitem' => null
			]
		];

		# 2
		$provider[] = [
			'Foo', 'bar', '', null,
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'  => 'Foo',
				'datatype' => 'bar',
				'lang'     => '',
				'dataitem' => null
			]
		];

		# 3
		$provider[] = [
			'Foo', 'bar', '', new DIWikiPage( 'Foo', NS_MAIN ),
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'   => 'Foo',
				'datatype'  => 'bar',
				'lang'      => '',
				'dataitem' => [
					'type' => DataItem::TYPE_WIKIPAGE,
					'item' => 'Foo#0##'
				]
			]
		];

		# 4
		$provider[] = [
			'Foo', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString', 'en', new DIWikiPage( 'Foo', NS_MAIN ),
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'   => 'Foo',
				'datatype'  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString',
				'lang'      => 'en',
				'dataitem' => [
					'type' => DataItem::TYPE_WIKIPAGE,
					'item' => 'Foo#0##'
				]
			]
		];

		return $provider;
	}

	public function invalidConstructorProvider() {
		# 0
		$provider[] = [
			[], '', '', null
		];

		# 1
		$provider[] = [
			'', [], '', null
		];

		# 1
		$provider[] = [
			'', '', [], null
		];

		return $provider;
	}

	public function serializationMissingElementProvider() {
		# 0
		$provider[] = [
			[]
		];

		# 1 Missing dataitem
		$provider[] = [
			[
				'type' => ExpLiteral::TYPE_LITERAL
			]
		];

		# 2 Bogus type
		$provider[] = [
			[
				'type' => 'BogusType'
			]
		];

		# 3 Missing uri
		$provider[] = [
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'dataitem' => null
			]
		];

		# 4 Missing lexical
		$provider[] = [
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'datatype' => 'foo',
				'dataitem' => null
			]
		];

		# 4 Missing datatype
		$provider[] = [
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'  => 'foo',
				'dataitem' => null
			]
		];

		# 5 Missing lang
		$provider[] = [
			[
				'type' => ExpLiteral::TYPE_LITERAL,
				'lexical'  => 'foo',
				'datatype' => 'foo',
				'dataitem' => null
			]
		];

		return $provider;
	}

}
