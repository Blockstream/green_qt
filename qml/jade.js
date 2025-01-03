function image(target, index) {
    if (target instanceof JadeDevice) {
        target = target.versionInfo?.BOARD_TYPE
    }
    const version = target === 'JADE_V2' ? 'jade2' : 'jade'
    return `qrc:/png/${version}_${index}.png`
}
