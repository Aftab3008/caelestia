Name:           caelestia-firefox-theme
Version:        1.0.0
Release:        1%{?dist}
Summary:        Native messaging host for the CaelestiaFox Firefox theme
License:        GPL-3.0-only
URL:            https://github.com/caelestia-dots/caelestia
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       fish
Requires:       jq
Requires:       inotify-tools

%description
The native messaging host component of the CaelestiaFox Firefox extension.
It watches the Caelestia color scheme file and pipes it into Firefox
so that the browser theme updates in real time when the color scheme changes.

%prep
%setup -q -c

%install
install -Dm644 %{_sourcedir}/manifest.json \
    %{buildroot}%{_libdir}/mozilla/native-messaging-hosts/caelestiafox.json
install -Dm755 %{_sourcedir}/app.fish \
    %{buildroot}%{_libdir}/caelestia/caelestiafox

%files
%license LICENSE
%{_libdir}/mozilla/native-messaging-hosts/caelestiafox.json
%{_libdir}/caelestia/caelestiafox

%post
echo '=> This is the native app component of the CaelestiaFox Firefox extension.'
echo '=> For the extension to work properly, please install the Firefox extension itself:'
echo '=> https://addons.mozilla.org/en-US/firefox/addon/caelestiafox'
