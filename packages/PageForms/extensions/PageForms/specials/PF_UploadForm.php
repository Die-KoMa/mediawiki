<?php
/**
 * Subclass of HTMLForm that provides the form section of Special:UploadWindow.
 *
 * @author Yaron Koren
 * @file
 * @ingroup PF
 */

use MediaWiki\Linker\LinkRenderer;

/**
 * @ingroup PFSpecialPages
 */
class PFUploadForm extends HTMLForm {
	protected $mWatch;
	protected $mForReUpload;
	protected $mSessionKey;
	protected $mHideIgnoreWarning;
	protected $mDestWarningAck;

	protected $mSourceIds;

	/** @var string raw html */
	protected $mTextTop;
	/** @var string raw html */
	protected $mTextAfterSummary;

	/** @var array */
	protected $mMaxUploadSize = [];

	/** @var string */
	private $mDestFile;

	/**
	 * @param array $options
	 * @param IContextSource|null $context
	 * @param LinkRenderer|null $linkRenderer
	 * @param LocalRepo|null $localRepo
	 * @param Language|null $contentLanguage
	 * @param NamespaceInfo|null $nsInfo
	 */
	public function __construct(
		array $options = [],
		IContextSource $context = null,
		LinkRenderer $linkRenderer = null,
		LocalRepo $localRepo = null,
		Language $contentLanguage = null,
		NamespaceInfo $nsInfo = null
	) {
		if ( $context instanceof IContextSource ) {
			$this->setContext( $context );
		}

		$this->mWatch = !empty( $options['watch'] );
		$this->mForReUpload = !empty( $options['forreupload'] );
		$this->mSessionKey = $options['sessionkey'] ?? '';
		$this->mHideIgnoreWarning = !empty( $options['hideignorewarning'] );
		$this->mDestFile = $options['destfile'] ?? '';

		$this->mTextTop = $options['texttop'] ?? '';
		$this->mTextAfterSummary = $options['textaftersummary'] ?? '';

		$sourceDescriptor = $this->getSourceSection();
		$descriptor = $sourceDescriptor
			+ $this->getDescriptionSection()
			+ $this->getOptionsSection();

		Hooks::run( 'UploadFormInitDescriptor', [ &$descriptor ] );
		parent::__construct( $descriptor, $this->getContext() );

		# Set some form properties
		$this->setSubmitTextMsg( 'uploadbtn' );
		$this->setSubmitName( 'wpUpload' );
		# Used message keys: 'accesskey-upload', 'tooltip-upload'
		$this->setSubmitTooltip( 'upload' );
		$this->setId( 'mw-upload-form' );

		# Build a list of IDs for javascript insertion
		$this->mSourceIds = [];
		foreach ( $sourceDescriptor as $field ) {
			if ( !empty( $field['id'] ) ) {
				$this->mSourceIds[] = $field['id'];
			}
		}
		// added for Page Forms
		$this->addHiddenField( 'pfInputID', $options['pfInputID'] );
		$this->addHiddenField( 'pfDelimiter', $options['pfDelimiter'] );
	}

	/**
	 * Get the descriptor of the fieldset that contains the file source
	 * selection. The section is 'source'
	 *
	 * @return array Descriptor array
	 */
	protected function getSourceSection() {
		if ( $this->mSessionKey ) {
			return [
				'SessionKey' => [
					'id' => 'wpSessionKey',
					'type' => 'hidden',
					'default' => $this->mSessionKey,
				],
				'SourceType' => [
					'id' => 'wpSourceType',
					'type' => 'hidden',
					'default' => 'Stash',
				],
			];
		}

		$canUploadByUrl = UploadFromUrl::isEnabled()
			&& ( UploadFromUrl::isAllowed( $this->getUser() ) === true )
			&& $this->getConfig()->get( 'CopyUploadsFromSpecialUpload' );
		$radio = $canUploadByUrl;
		$selectedSourceType = strtolower( $this->getRequest()->getText( 'wpSourceType', 'File' ) );

		$descriptor = [];

		if ( $this->mTextTop ) {
			$descriptor['UploadFormTextTop'] = [
				'type' => 'info',
				'section' => 'source',
				'default' => $this->mTextTop,
				'raw' => true,
			];
		}

		$this->mMaxUploadSize['file'] = min(
			UploadBase::getMaxUploadSize( 'file' ),
			UploadBase::getMaxPhpUploadSize()
		);

		$help = $this->msg( 'upload-maxfilesize',
				$this->getContext()->getLanguage()->formatSize( $this->mMaxUploadSize['file'] )
			)->parse();

		// If the user can also upload by URL, there are 2 different file size limits.
		// This extra message helps stress which limit corresponds to what.
		if ( $canUploadByUrl ) {
			$help .= $this->msg( 'word-separator' )->escaped();
			$help .= $this->msg( 'upload_source_file' )->parse();
		}

		$descriptor['UploadFile'] = [
			'class' => PFUploadSourceField::class,
			'section' => 'source',
			'type' => 'file',
			'id' => 'wpUploadFile',
			'label-message' => 'sourcefilename',
			'upload-type' => 'File',
			'radio' => &$radio,
			'help' => $help,
			'checked' => $selectedSourceType == 'file',
		];
		if ( $canUploadByUrl ) {
			$descriptor['UploadFileURL'] = [
				'class' => UploadSourceField::class,
				'section' => 'source',
				'id' => 'wpUploadFileURL',
				'label-message' => 'sourceurl',
				'upload-type' => 'url',
				'radio' => &$radio,
				'help' => $this->msg( 'upload-maxfilesize',
					$this->getContext()->getLanguage()->formatSize( $this->mMaxUploadSize['url'] )
				)->parse() .
					$this->msg( 'word-separator' )->escaped() .
					$this->msg( 'upload_source_url' )->parse(),
				'checked' => $selectedSourceType == 'url',
			];
		}
		Hooks::run( 'UploadFormSourceDescriptors', [ &$descriptor, &$radio, $selectedSourceType ] );

		$descriptor['Extensions'] = [
			'type' => 'info',
			'section' => 'source',
			'default' => $this->getExtensionsMessage(),
			'raw' => true,
		];
		return $descriptor;
	}

	/**
	 * Get the messages indicating which extensions are preferred and prohibitted.
	 *
	 * @return string HTML string containing the message
	 */
	protected function getExtensionsMessage() {
		# Print a list of allowed file extensions, if so configured. We ignore
		# MIME type here, it's incomprehensible to most people and too long.
		global $wgCheckFileExtensions, $wgStrictFileExtensions,
		$wgFileExtensions, $wgFileBlacklist;

		if ( $wgCheckFileExtensions ) {
			if ( $wgStrictFileExtensions ) {
				# Everything not permitted is banned
				$extensionsList =
					'<div id="mw-upload-permitted">' .
						$this->msg( 'upload-permitted', $this->getLanguage()->commaList( $wgFileExtensions ) )->parse() .
					"</div>\n";
			} else {
				# We have to list both preferred and prohibited
				$extensionsList =
					'<div id="mw-upload-preferred">' .
						$this->msg( 'upload-preferred', $this->getLanguage()->commaList( $wgFileExtensions ) )->parse() .
					"</div>\n" .
					'<div id="mw-upload-prohibited">' .
						$this->msg( 'upload-prohibited', $this->getLanguage()->commaList( $wgFileBlacklist ) )->parse() .
					"</div>\n";
			}
		} else {
			# Everything is permitted.
			$extensionsList = '';
		}
		return $extensionsList;
	}

	/**
	 * Get the descriptor of the fieldset that contains the file description
	 * input. The section is 'description'
	 *
	 * @return array Descriptor array
	 */
	protected function getDescriptionSection() {
		$descriptor = [
			'DestFile' => [
				'type' => 'text',
				'section' => 'description',
				'id' => 'wpDestFile',
				'label-message' => 'destfilename',
				'size' => 60,
				'default' => $this->mDestFile,
				# @todo FIXME: Hack to work around poor handling of the 'default' option in HTMLForm
				'nodata' => strval( $this->mDestFile ) !== '',
			],
			'UploadDescription' => [
				'type' => 'textarea',
				'section' => 'description',
				'id' => 'wpUploadDescription',
				'label-message' => $this->mForReUpload
					? 'filereuploadsummary'
					: 'fileuploadsummary',
				'cols' => 80,
				'rows' => 4,
				'default' => '',
			],
/*
			'EditTools' => array(
				'type' => 'edittools',
				'section' => 'description',
			),
*/
			'License' => [
				'type' => 'select',
				'class' => 'Licenses',
				'section' => 'description',
				'id' => 'wpLicense',
				'label-message' => 'license',
			],
		];

		if ( $this->mTextAfterSummary ) {
			$descriptor['UploadFormTextAfterSummary'] = [
				'type' => 'info',
				'section' => 'description',
				'default' => $this->mTextAfterSummary,
				'raw' => true,
			];
		}

		if ( $this->mForReUpload ) {
			$descriptor['DestFile']['readonly'] = true;
		}

		global $wgUseCopyrightUpload;
		if ( $wgUseCopyrightUpload ) {
			$descriptor['UploadCopyStatus'] = [
				'type' => 'text',
				'section' => 'description',
				'id' => 'wpUploadCopyStatus',
				'label-message' => 'filestatus',
			];
			$descriptor['UploadSource'] = [
				'type' => 'text',
				'section' => 'description',
				'id' => 'wpUploadSource',
				'label-message' => 'filesource',
			];
		}

		return $descriptor;
	}

	/**
	 * Get the descriptor of the fieldset that contains the upload options,
	 * such as "watch this file". The section is 'options'
	 *
	 * @return array Descriptor array
	 */
	protected function getOptionsSection() {
		$descriptor = [
			'Watchthis' => [
				'type' => 'check',
				'id' => 'wpWatchthis',
				'label-message' => 'watchthisupload',
				'section' => 'options',
			]
		];
		if ( !$this->mHideIgnoreWarning ) {
			$descriptor['IgnoreWarning'] = [
				'type' => 'check',
				'id' => 'wpIgnoreWarning',
				'label-message' => 'ignorewarnings',
				'section' => 'options',
			];
		}
		$descriptor['DestFileWarningAck'] = [
			'type' => 'hidden',
			'id' => 'wpDestFileWarningAck',
			'default' => $this->mDestWarningAck ? '1' : '',
		];

		return $descriptor;
	}

	/**
	 * Add the upload JS and show the form.
	 * @inheritDoc
	 */
	public function show() {
		// $this->addUploadJS();
		parent::show();
		// disable output - we'll print out the page manually,
		// taking the body created by the form, plus the necessary
		// Javascript files, and turning them into an HTML page
		global $wgTitle, $wgLanguageCode, $wgScriptPath,
			$wgPageFormsScriptPath,
			$wgXhtmlDefaultNamespace, $wgXhtmlNamespaces;

		$out = $this->getOutput();

		$out->disable();
		$wgTitle = SpecialPage::getTitleFor( 'Upload' );

		$text = <<<END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="{$wgXhtmlDefaultNamespace}"
END;
		foreach ( $wgXhtmlNamespaces as $tag => $ns ) {
			$text .= "xmlns:{$tag}=\"{$ns}\" ";
		}
		$dir = PFUtils::getContLang()->isRTL() ? "rtl" : "ltr";
		$text .= "xml:lang=\"{$wgLanguageCode}\" lang=\"{$wgLanguageCode}\" dir=\"{$dir}\">";

		$text .= <<<END

<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<head>
<script src="{$wgScriptPath}/resources/lib/jquery/jquery.js"></script>
<script src="{$wgPageFormsScriptPath}/libs/PF_upload.js"></script>
</head>
<body>
{$out->getHTML()}
</body>
</html>


END;
		print $text;
		return true;
	}

	/**
	 * Empty function; submission is handled elsewhere.
	 *
	 * @return bool False
	 */
	public function trySubmit() {
		return false;
	}

}
