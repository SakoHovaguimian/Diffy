#!/usr/bin/env python3
"""Refresh explicit Xcode source membership without invoking Xcode or building."""

from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'Diffy'
PROJECT = ROOT / 'Diffy.xcodeproj'


def identifier(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def quote(value):
    return json.dumps(str(value))


def generate():
    objects = []
    source_builds = []
    resource_builds = []

    def add(key, body):
        objects.append(f'\t\t{identifier(key)} = {{ {body} }};')
        return identifier(key)

    def group(directory):
        children = []

        for path in sorted(directory.iterdir(), key=lambda item: (item.is_file(), item.name)):
            relative = str(path.relative_to(ROOT))

            if path == APP / 'Resources' / 'Fonts':
                reference = add(relative, f'isa = PBXFileReference; lastKnownFileType = folder; path = {quote(path.name)}; sourceTree = "<group>";')
                children.append(reference)
                resource_builds.append(add('build:' + relative, f'isa = PBXBuildFile; fileRef = {reference};'))
            elif path.is_dir():
                children.append(group(path))
            elif path.suffix in ('.swift', '.entitlements'):
                kind = 'sourcecode.swift' if path.suffix == '.swift' else 'text.plist.entitlements'
                reference = add(relative, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(path.name)}; sourceTree = "<group>";')
                children.append(reference)

                if path.suffix == '.swift':
                    source_builds.append(add('build:' + relative, f'isa = PBXBuildFile; fileRef = {reference};'))

        return add('group:' + str(directory.relative_to(ROOT)), f'isa = PBXGroup; children = ({", ".join(children)}); path = {quote(directory.name)}; sourceTree = "<group>";')

    app_group = group(APP)
    product = add('product', 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Diffy.app; sourceTree = BUILT_PRODUCTS_DIR;')
    products = add('products', f'isa = PBXGroup; children = ({product}); name = Products; sourceTree = "<group>";')
    main = add('main', f'isa = PBXGroup; children = ({app_group}, {products}); sourceTree = "<group>";')
    sources = add('sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(source_builds)}); runOnlyForDeploymentPostprocessing = 0;')
    resources = add('resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(resource_builds)}); runOnlyForDeploymentPostprocessing = 0;')
    frameworks = add('frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')

    project_configs = []
    target_configs = []

    for configuration in ('Debug', 'Release'):
        project_settings = {
            'MACOSX_DEPLOYMENT_TARGET': '14.0',
            'SDKROOT': 'macosx',
            'SWIFT_VERSION': '6.0',
            'CLANG_ENABLE_MODULES': 'YES',
            'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if configuration == 'Debug' else '-O',
            'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG' if configuration == 'Debug' else '',
        }
        target_settings = {
            'PRODUCT_NAME': 'Diffy',
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.diffy.app',
            'GENERATE_INFOPLIST_FILE': 'YES',
            'INFOPLIST_KEY_CFBundleDisplayName': 'Diffy',
            'INFOPLIST_KEY_ATSApplicationFontsPath': 'Fonts/',
            'INFOPLIST_KEY_LSApplicationCategoryType': 'public.app-category.developer-tools',
            'CODE_SIGN_STYLE': 'Automatic',
            'CODE_SIGN_IDENTITY': '-',
            'CODE_SIGN_ENTITLEMENTS': 'Diffy/Resources/Diffy.entitlements',
            'ENABLE_APP_SANDBOX': 'YES',
            'ENABLE_USER_SELECTED_FILES': 'readwrite',
            'ENABLE_HARDENED_RUNTIME': 'YES',
            'MARKETING_VERSION': '0.1.0',
            'CURRENT_PROJECT_VERSION': '1',
            'COMBINE_HIDPI_IMAGES': 'YES',
            'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/../Frameworks',
        }

        def settings(values):
            return ' '.join(f'{key} = {quote(value)};' for key, value in values.items())

        project_configs.append(add('project:' + configuration, f'isa = XCBuildConfiguration; buildSettings = {{ {settings(project_settings)} }}; name = {configuration};'))
        target_configs.append(add('target:' + configuration, f'isa = XCBuildConfiguration; buildSettings = {{ {settings(target_settings)} }}; name = {configuration};'))

    def configurations(key, values):
        return add(key, f'isa = XCConfigurationList; buildConfigurations = ({", ".join(values)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

    project_list = configurations('project-configurations', project_configs)
    target_list = configurations('target-configurations', target_configs)
    target = add('target', f'isa = PBXNativeTarget; buildConfigurationList = {target_list}; buildPhases = ({sources}, {frameworks}, {resources}); buildRules = (); dependencies = (); name = Diffy; productName = Diffy; productReference = {product}; productType = "com.apple.product-type.application";')
    project = add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; }}; buildConfigurationList = {project_list}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = ({target});')

    PROJECT.mkdir(exist_ok=True)
    (PROJECT / 'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + f'\n\t}};\n\trootObject = {project};\n}}\n')
    schemes = PROJECT / 'xcshareddata/xcschemes'
    schemes.mkdir(parents=True, exist_ok=True)
    reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="Diffy.app" BlueprintName="Diffy" ReferencedContainer="container:Diffy.xcodeproj"/>'
    (schemes / 'Diffy.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="NO" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="NO">
    <BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
    print(f'Generated Diffy.xcodeproj with {len(source_builds)} explicit Swift source entries.')


if __name__ == '__main__':
    generate()
