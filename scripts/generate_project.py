#!/usr/bin/env python3
"""Refresh explicit Xcode source membership without invoking Xcode or building.

Generates two application targets and shared schemes:

- Diffy Live (com.diffy.app): every Swift source, compiled with DIFFY_LIVE.
- Diffy Mock (com.diffy.app.mock): every Swift source except files inside a `Live/`
  folder, compiled with DIFFY_MOCK. The mock binary therefore contains no Git process,
  network, Keychain, or live-storage code.

Mock services and fixtures are members of both targets because SwiftUI previews are
always mock-backed.
"""

from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'Diffy'
CONFIG = ROOT / 'Config'
PROJECT = ROOT / 'Diffy.xcodeproj'
SCHEMES = PROJECT / 'xcshareddata' / 'xcschemes'

# Schemes this generator produced in earlier versions and now replaces.
RETIRED_SCHEMES = ('Diffy.xcscheme',)

FILE_KINDS = {
    '.swift': 'sourcecode.swift',
    '.entitlements': 'text.plist.entitlements',
    '.plist': 'text.plist.xml',
    '.xcconfig': 'text.xcconfig',
}

TARGETS = (
    {
        'key': 'live',
        'name': 'Diffy Live',
        'product': 'Diffy',
        'bundle_identifier': 'com.diffy.app',
        'display_name': 'Diffy',
        'condition': 'DIFFY_LIVE',
        'entitlements': 'Diffy/Resources/DiffyLive.entitlements',
        'network_client': 'YES',
        'xcconfig': 'Config/DiffyLive.xcconfig',
        'includes_live_sources': True,
        'extra_settings': {},
    },
    {
        'key': 'mock',
        'name': 'Diffy Mock',
        'product': 'Diffy Mock',
        'bundle_identifier': 'com.diffy.app.mock',
        'display_name': 'Diffy Mock',
        'condition': 'DIFFY_MOCK',
        'entitlements': 'Diffy/Resources/DiffyMock.entitlements',
        'network_client': 'NO',
        'xcconfig': None,
        'includes_live_sources': False,
        # The mock never reads GitHub configuration; keep the Info.plist keys empty.
        'extra_settings': {
            'DIFFY_GITHUB_CLIENT_ID': '',
            'DIFFY_GITHUB_HOST': '',
            'DIFFY_GITHUB_APP_SLUG': '',
        },
    },
)


def identifier(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()


def quote(value):
    return json.dumps(str(value))


def is_live_only(relative_path):
    return 'Live' in Path(relative_path).parts


def settings_text(values):
    return ' '.join(f'{key} = {quote(value)};' for key, value in values.items())


class ProjectWriter:

    def __init__(self):
        self.objects = []
        self.swift_sources = []
        self.font_folder = None
        self.references = {}

    # MARK: - Objects

    def add(self, key, body):
        self.objects.append(f'\t\t{identifier(key)} = {{ {body} }};')
        return identifier(key)

    def file_reference(self, relative, name, kind):
        reference = self.add(relative, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(name)}; sourceTree = "<group>";')
        self.references[relative] = reference
        return reference

    # MARK: - Groups

    def group(self, directory):
        children = []

        for path in sorted(directory.iterdir(), key=lambda item: (item.is_file(), item.name)):
            relative = str(path.relative_to(ROOT))

            if path == APP / 'Resources' / 'Fonts':
                reference = self.add(relative, f'isa = PBXFileReference; lastKnownFileType = folder; path = {quote(path.name)}; sourceTree = "<group>";')
                self.font_folder = reference
                children.append(reference)
            elif path.is_dir():
                children.append(self.group(path))
            elif path.suffix in FILE_KINDS:
                children.append(self.file_reference(relative, path.name, FILE_KINDS[path.suffix]))

                if path.suffix == '.swift':
                    self.swift_sources.append(relative)

        return self.add('group:' + str(directory.relative_to(ROOT)), f'isa = PBXGroup; children = ({", ".join(children)}); path = {quote(directory.name)}; sourceTree = "<group>";')

    # MARK: - Targets

    def target_sources(self, target):
        return [path for path in self.swift_sources if target['includes_live_sources'] or not is_live_only(path)]

    def build_phases(self, target):
        key = target['key']
        sources = self.target_sources(target)
        source_builds = [self.add(f'build:{key}:{path}', f'isa = PBXBuildFile; fileRef = {self.references[path]};') for path in sources]
        resource_builds = [self.add(f'build:{key}:fonts', f'isa = PBXBuildFile; fileRef = {self.font_folder};')] if self.font_folder else []

        return (
            self.add(f'sources:{key}', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(source_builds)}); runOnlyForDeploymentPostprocessing = 0;'),
            self.add(f'frameworks:{key}', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;'),
            self.add(f'resources:{key}', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({", ".join(resource_builds)}); runOnlyForDeploymentPostprocessing = 0;'),
            len(source_builds),
        )

    def target_settings(self, target, configuration):
        conditions = [target['condition']]

        if configuration == 'Debug':
            conditions.insert(0, 'DEBUG')

        values = {
            'PRODUCT_NAME': target['product'],
            'PRODUCT_MODULE_NAME': 'Diffy',
            'PRODUCT_BUNDLE_IDENTIFIER': target['bundle_identifier'],
            'DIFFY_DISPLAY_NAME': target['display_name'],
            'SWIFT_ACTIVE_COMPILATION_CONDITIONS': ' '.join(conditions),
            'GENERATE_INFOPLIST_FILE': 'NO',
            'INFOPLIST_FILE': 'Diffy/Resources/Info.plist',
            'CODE_SIGN_STYLE': 'Automatic',
            'CODE_SIGN_IDENTITY': '-',
            'CODE_SIGN_ENTITLEMENTS': target['entitlements'],
            'ENABLE_APP_SANDBOX': 'YES',
            'ENABLE_USER_SELECTED_FILES': 'readwrite',
            'ENABLE_OUTGOING_NETWORK_CONNECTIONS': target['network_client'],
            'ENABLE_HARDENED_RUNTIME': 'YES',
            'MARKETING_VERSION': '0.1.0',
            'CURRENT_PROJECT_VERSION': '1',
            'COMBINE_HIDPI_IMAGES': 'YES',
            'LD_RUNPATH_SEARCH_PATHS': '$(inherited) @executable_path/../Frameworks',
        }
        values.update(target['extra_settings'])

        return values

    def configuration_list(self, key, configurations):
        return self.add(key, f'isa = XCConfigurationList; buildConfigurations = ({", ".join(configurations)}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

    def target(self, target, product):
        key = target['key']
        sources, frameworks, resources, source_count = self.build_phases(target)
        base_reference = self.references.get(target['xcconfig']) if target['xcconfig'] else None
        configurations = []

        for configuration in ('Debug', 'Release'):
            base = f' baseConfigurationReference = {base_reference};' if base_reference else ''
            body = f'isa = XCBuildConfiguration;{base} buildSettings = {{ {settings_text(self.target_settings(target, configuration))} }}; name = {configuration};'
            configurations.append(self.add(f'target:{key}:{configuration}', body))

        configuration_list = self.configuration_list(f'target-configurations:{key}', configurations)
        native_target = self.add(f'target:{key}', f'isa = PBXNativeTarget; buildConfigurationList = {configuration_list}; buildPhases = ({sources}, {frameworks}, {resources}); buildRules = (); dependencies = (); name = {quote(target["name"])}; productName = {quote(target["product"])}; productReference = {product}; productType = "com.apple.product-type.application";')

        return native_target, source_count

    # MARK: - Project

    def project_configurations(self):
        configurations = []

        for configuration in ('Debug', 'Release'):
            values = {
                'MACOSX_DEPLOYMENT_TARGET': '14.0',
                'SDKROOT': 'macosx',
                'SWIFT_VERSION': '6.0',
                'CLANG_ENABLE_MODULES': 'YES',
                'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if configuration == 'Debug' else '-O',
            }
            configurations.append(self.add('project:' + configuration, f'isa = XCBuildConfiguration; buildSettings = {{ {settings_text(values)} }}; name = {configuration};'))

        return self.configuration_list('project-configurations', configurations)

    def write(self):
        app_group = self.group(APP)
        config_group = self.group(CONFIG)
        products = {target['key']: self.add(f'product:{target["key"]}', f'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {quote(target["product"] + ".app")}; sourceTree = BUILT_PRODUCTS_DIR;') for target in TARGETS}
        products_group = self.add('products', f'isa = PBXGroup; children = ({", ".join(products.values())}); name = Products; sourceTree = "<group>";')
        main = self.add('main', f'isa = PBXGroup; children = ({app_group}, {config_group}, {products_group}); sourceTree = "<group>";')
        project_list = self.project_configurations()
        native_targets = {target['key']: self.target(target, products[target['key']]) for target in TARGETS}
        target_ids = ', '.join(native_target for native_target, _ in native_targets.values())
        project = self.add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; }}; buildConfigurationList = {project_list}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {main}; productRefGroup = {products_group}; projectDirPath = ""; projectRoot = ""; targets = ({target_ids});')

        PROJECT.mkdir(exist_ok=True)
        (PROJECT / 'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(self.objects) + f'\n\t}};\n\trootObject = {project};\n}}\n')

        return native_targets


# MARK: - Schemes

def scheme_text(target, blueprint):
    reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{blueprint}" BuildableName="{target["product"]}.app" BlueprintName="{target["name"]}" ReferencedContainer="container:Diffy.xcodeproj"/>'

    return f'''<?xml version="1.0" encoding="UTF-8"?>
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
'''


def write_schemes(native_targets):
    SCHEMES.mkdir(parents=True, exist_ok=True)

    for retired in RETIRED_SCHEMES:
        (SCHEMES / retired).unlink(missing_ok=True)

    for target in TARGETS:
        blueprint, _ = native_targets[target['key']]
        (SCHEMES / f'{target["name"]}.xcscheme').write_text(scheme_text(target, blueprint))


def generate():
    writer = ProjectWriter()
    native_targets = writer.write()
    write_schemes(native_targets)

    counts = ', '.join(f'{target["name"]}: {native_targets[target["key"]][1]} Swift sources' for target in TARGETS)
    print(f'Generated Diffy.xcodeproj ({counts}).')


if __name__ == '__main__':
    generate()
