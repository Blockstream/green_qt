.pragma library

// Token names and design IDs only; preview values come from Colors and Theme.typography.
var colorGroups = [
    {
        'title': 'Text',
        'tokens': [
            { name: 'textBrand', designId: 'text/brand' },
            { name: 'textBrandHover', designId: 'text/brand-hover' },
            { name: 'textDisabled', designId: 'text/disabled' },
            { name: 'textInverse', designId: 'text/inverse' },
            { name: 'textPrimary', designId: 'text/primary' },
            { name: 'textSubtle', designId: 'text/subtle' }
        ]
    },
    {
        'title': 'Action',
        'tokens': [
            { name: 'actionPrimary', designId: 'action/primary' },
            { name: 'actionHover', designId: 'action/hover' },
            { name: 'actionPressed', designId: 'action/pressed' },
            { name: 'actionDisabled', designId: 'action/disabled' },
            { name: 'actionOnPrimary', designId: 'action/on-primary' },
            { name: 'actionOnPrimaryInverted', designId: 'action/on-primary-inverted' },
            { name: 'actionPrimaryInverted', designId: 'action/primary-inverted' },
            { name: 'actionPrimaryInvertedDisabled', designId: 'action/primary-inverted-disabled' },
            { name: 'actionPrimaryInvertedPressed', designId: 'action/primary-inverted-pressed' }
        ]
    },
    {
        'title': 'Border',
        'tokens': [
            { name: 'borderBold', designId: 'border/bold' },
            { name: 'borderBrand', designId: 'border/brand' },
            { name: 'borderFocus', designId: 'border/focus' },
            { name: 'borderInverse', designId: 'border/inverse' },
            { name: 'borderSubtle', designId: 'border/subtle' }
        ]
    },
    {
        'title': 'Feedback',
        'tokens': [
            { name: 'feedbackInfoAccent', designId: 'feedback/info/accent' },
            { name: 'feedbackInfoFill', designId: 'feedback/info/fill' },
            { name: 'feedbackInfoOnFill', designId: 'feedback/info/on-fill' },
            { name: 'feedbackInfoStroke', designId: 'feedback/info/stroke' },
            { name: 'feedbackNegativeAccent', designId: 'feedback/negative/accent' },
            { name: 'feedbackNegativeFill', designId: 'feedback/negative/fill' },
            { name: 'feedbackNegativeOnFill', designId: 'feedback/negative/on-fill' },
            { name: 'feedbackNegativeStroke', designId: 'feedback/negative/stroke' },
            { name: 'feedbackPositiveAccent', designId: 'feedback/positive/accent' },
            { name: 'feedbackPositiveFill', designId: 'feedback/positive/fill' },
            { name: 'feedbackPositiveOnFill', designId: 'feedback/positive/on-fill' },
            { name: 'feedbackPositiveStroke', designId: 'feedback/positive/stroke' },
            { name: 'feedbackWarningAccent', designId: 'feedback/warning/accent' },
            { name: 'feedbackWarningFill', designId: 'feedback/warning/fill' },
            { name: 'feedbackWarningOnFill', designId: 'feedback/warning/on-fill' },
            { name: 'feedbackWarningStroke', designId: 'feedback/warning/stroke' }
        ]
    },
    {
        'title': 'Icon',
        'tokens': [
            { name: 'iconBase', designId: 'icon/base' },
            { name: 'iconBrand', designId: 'icon/brand' },
            { name: 'iconDisabled', designId: 'icon/disabled' },
            { name: 'iconInverse', designId: 'icon/inverse' },
            { name: 'iconSubtle', designId: 'icon/subtle' }
        ]
    },
    {
        'title': 'Overlay',
        'tokens': [
            { name: 'overlayScrim', designId: 'overlay/scrim' }
        ]
    },
    {
        'title': 'Surface',
        'tokens': [
            { name: 'surfaceBase', designId: 'surface/base' },
            { name: 'surfaceCanvas', designId: 'surface/canvas' },
            { name: 'surfaceHover', designId: 'surface/hover' },
            { name: 'surfaceOverlay', designId: 'surface/overlay' },
            { name: 'surfaceRaised', designId: 'surface/raised' },
            { name: 'surfaceScrim', designId: 'surface/scrim' },
            { name: 'surfaceSunken', designId: 'surface/sunken' },
            { name: 'surfaceSegmentedSelected', designId: 'surface/segmented/selected' }
        ]
    }
];

var typographyGroups = [
    {
        'title': 'Body',
        'tokens': [
            { name: 'bodyL', designId: 'body/l' },
            { name: 'bodyM', designId: 'body/m' },
            { name: 'bodyS', designId: 'body/s' }
        ]
    },
    {
        'title': 'Code',
        'tokens': [
            { name: 'codeM', designId: 'code/m' },
            { name: 'codeS', designId: 'code/s' }
        ]
    },
    {
        'title': 'Display',
        'tokens': [
            { name: 'displayLSemibold', designId: 'display/l-semibold' },
            { name: 'displayMMedium', designId: 'display/m-medium' },
            { name: 'displayMSemibold', designId: 'display/m-semibold' },
            { name: 'displaySMedium', designId: 'display/s-medium' },
            { name: 'displayXlMedium', designId: 'display/xl-medium' }
        ]
    },
    {
        'title': 'Label',
        'tokens': [
            { name: 'labelL', designId: 'label/l' },
            { name: 'labelLMedium', designId: 'label/l-medium' },
            { name: 'labelLSemibold', designId: 'label/l-semibold' },
            { name: 'labelM', designId: 'label/m' },
            { name: 'labelMMedium', designId: 'label/m-medium' },
            { name: 'labelMSemibold', designId: 'label/m-semibold' },
            { name: 'labelSm', designId: 'label/sm' },
            { name: 'labelSmSemibold', designId: 'label/sm-semibold' },
            { name: 'labelXs', designId: 'label/xs' }
        ]
    },
    {
        'title': 'Overline',
        'tokens': [
            { name: 'overlineS', designId: 'overline/s' },
            { name: 'overlineSSemibold', designId: 'overline/s-semibold' },
            { name: 'overlineXs', designId: 'overline/xs' }
        ]
    },
    {
        'title': 'Title',
        'tokens': [
            { name: 'titleLBold', designId: 'title/l-bold' },
            { name: 'titleLMedium', designId: 'title/l-medium' },
            { name: 'titleLSemibold', designId: 'title/l-semibold' },
            { name: 'titleM', designId: 'title/m' },
            { name: 'titleMSemibold', designId: 'title/m-semibold' },
            { name: 'titleSBold', designId: 'title/s-bold' },
            { name: 'titleSSemibold', designId: 'title/s-semibold' },
            { name: 'titleXl', designId: 'title/xl' },
            { name: 'titleXlMedium', designId: 'title/xl-medium' },
            { name: 'titleXlSemibold', designId: 'title/xl-semibold' },
            { name: 'titleXsBold', designId: 'title/xs-bold' },
            { name: 'titleXxlBold', designId: 'title/xxl-bold' }
        ]
    }
];
