set(TS_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/green_cs.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_de.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_en.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_es.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_fr.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_he.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_it.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_ja.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_nl.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_pt_BR.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_pt_PT.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_ro.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_ru.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_uk.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_vi.ts
    ${CMAKE_CURRENT_SOURCE_DIR}/green_zh.ts
)

qt_add_translations(${APP_TARGET}
    IMMEDIATE_CALL
    SOURCE_TARGETS ${APP_TARGET}
    TS_FILES ${TS_FILES}
    QM_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
    RESOURCE_PREFIX "/i18n"
)
