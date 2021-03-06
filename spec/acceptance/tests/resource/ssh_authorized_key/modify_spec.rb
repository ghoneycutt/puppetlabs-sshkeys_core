require 'spec_helper_acceptance'

RSpec.context 'sshkeys: Modify' do
  let(:auth_keys) { '~/.ssh/authorized_keys' }
  let(:name) { "pl#{rand(999_999).to_i}" }

  before(:each) do
    posix_agents.each do |agent|
      on(agent, "cp #{auth_keys} /tmp/auth_keys", acceptable_exit_codes: [0, 1])
      on(agent, "echo '' >> #{auth_keys} && echo 'ssh-rsa mykey #{name}' >> #{auth_keys}")
      on(agent, "chown $LOGNAME #{auth_keys}")
    end
  end

  after(:each) do
    posix_agents.each do |agent|
      # (teardown) restore the #{auth_keys} file
      on(agent, "mv /tmp/auth_keys #{auth_keys}", acceptable_exit_codes: [0, 1])
    end
  end

  posix_agents.each do |agent|
    it "#{agent} should update an entry for an SSH authorized key" do
      args = ['ensure=present',
              'user=$LOGNAME',
              "type='rsa'",
              "key='mynewshinykey'"]
      on(agent, puppet_resource('ssh_authorized_key', name.to_s, args))

      on(agent, "cat #{auth_keys}") do |_res|
        expect(stdout).to include("mynewshinykey #{name}")
        expect(stdout).not_to include("mykey #{name}")
      end
    end
  end
end
