class HomeAction < Cramp::Action
  @@template = ERB.new(File.read(CrampPubsub::Application.root('app/views/index.erb')))

  def start
    render @@template.result(binding)
    finish
  end
end
