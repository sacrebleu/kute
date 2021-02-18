require_relative '../cfg/kubeconfig'

describe KubeConfig do
  let(:cfg1) { File.join(File.dirname(__FILE__), 'fixtures/context') }
  let(:cfg2) { File.join(File.dirname(__FILE__), 'fixtures/context-2') }

  it 'Can parse the context file try to match up the current context by name' do
    # expect(subject.class).to
    # subject.class.context(name, )
  end

  it 'Loads the first example config' do
    expect(subject.class).to receive(:path).and_return(cfg1)
    data = subject.class.current_context

    expect(data).to_not be_nil
    pp data
  end

  it 'Loads the second example config' do
    expect(subject.class).to receive(:path).and_return(cfg2)
    data = subject.class.current_context

    expect(data).to_not be_nil
    pp data
  end

  it 'establishes the region and cluster name from a cluster context' do
    expect(subject.class).to receive(:path).and_return(cfg1)
    data = subject.class.current_context

    expect(data).to_not be_nil

    expect(data['region']).to eql('eu-central-1')
    expect(data['name']).to eql('arn:aws:eks:eu-west-1:11111:cluster/nexmo-eks-dev')
    expect(data['cluster_name']).to eql('arn:aws:eks:eu-west-1:11111:cluster/nexmo-eks-dev')
  end
end
