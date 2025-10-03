require 'spec_helper'

describe 'realmd' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }

        context 'realmd::sssd::config class with custom config' do
          let(:params) do
            {
              manage_sssd_config: true,
              sssd_config: {
                'sssd' => {
                  'domains'             => 'example.com',
                  'config_file_version' => '2',
                  'services'            => 'nss,pam',
                },
                'domain/example.com' => {
                  'ad_domain'                      => 'example.com',
                  'krb5_realm'                     => 'EXAMPLE.COM',
                  'id_provider'                    => 'ad',
                  'access_provider'                => 'ad',
                },
              }
            }
          end

          it do
            is_expected.to contain_file('/etc/sssd/sssd.conf')
              .with(
                owner: 'root',
                group: 'root',
                mode: '0600',
              )
          end

          it { is_expected.to contain_file('/etc/sssd/sssd.conf').that_notifies('Service[sssd]') }
          it { is_expected.to contain_file('/etc/sssd/sssd.conf').that_notifies('Exec[force_config_cache_rebuild]') }
          it { is_expected.to contain_file('/etc/sssd/sssd.conf').with_content(%r{services = nss,pam}) }
          it { is_expected.to contain_file('/etc/sssd/sssd.conf').with_content(%r{\[domain/example.com\]}) }
          it { is_expected.to contain_file('/etc/sssd/sssd.conf').with_content(%r{access_provider = ad}) }

          it do
            is_expected.to contain_exec('force_config_cache_rebuild')
              .with(
                path:        '/usr/bin:/usr/sbin:/bin',
                command:     'rm -f /var/lib/sss/db/config.ldb',
                refreshonly: true,
              )
          end
        end

        context 'realmd::sssd::config class with custom config file & mode' do
          let(:params) do
            {
              manage_sssd_config: true,
              sssd_config: { test: true },
              sssd_config_file: '/target/etc/sssd/sssd.conf',
              sssd_config_file_mode: '0640',
            }
          end

          it { is_expected.not_to contain_file('/etc/sssd/sssd.conf') }
          it { is_expected.to contain_file('/target/etc/sssd/sssd.conf').with_mode('0640') }
        end
      end
    end
  end
end
