cmake_minimum_required(VERSION 3.16)

project(CryptoKey VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appCryptoKey
    main.cpp
    DatabaseManager.cpp DatabaseManager.h
    qaesencryption.cpp qaesencryption.h
)

qt_add_qml_module(appCryptoKey
    URI CryptoKey
    QML_FILES
        Main.qml
        SOURCES DatabaseManager.h
        SOURCES DatabaseManager.cpp
        SOURCES
        SOURCES qaesencryption.h
        SOURCES qaesencryption.cpp
        SOURCES totp.h
        SOURCES totp.cpp
        QML_FILES TotpDisplay.qml
        RESOURCES
        QML_FILES
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appCryptoKey PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appCryptoKey
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appCryptoKey
    PRIVATE Qt6::Quick
            Qt6::Sql
)

include(GNUInstallDirs)
install(TARGETS appCryptoKey
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
