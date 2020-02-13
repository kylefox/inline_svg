require_relative '../lib/inline_svg/webpack_asset_finder'
require 'webmock'

describe InlineSvg::WebpackAssetFinder do
  include WebMock::API
  SVG_STRING = '<svg><!-- Pretty shapes go here --></svg>'.freeze

  before do
    WebMock.enable!

    Webpacker = double(
      'Webpacker',
      manifest: double('Webpacker.manifest'),
      dev_server: double('Webpacker.dev_server',
        host: 'webpack.test', port: 3035, https?: dev_server_uses_https, running?: dev_server_running
      )
    )

    allow(Webpacker.manifest).to receive(:lookup) { '/packs/media/example.svg' if asset_exists }

    stub_request(
      :get,
      "#{dev_server_uses_https ? 'https' : 'http'}://webpack.test:3035/packs/media/example.svg"
    ).to_return(
      status: asset_exists ? 200 : 404,
      body: SVG_STRING
    )

    Rails = double('Rails', logger: double)
    allow(Rails.logger).to receive(:error)
  end

  shared_examples 'valid SVG' do
    it { expect(subject.pathname.read).to eq SVG_STRING }
  end

  shared_examples 'invalid SVG' do
    it { expect(subject.pathname).to be nil }
  end

  subject { InlineSvg::WebpackAssetFinder.new('media/example.svg') }

  context 'asset exists' do
    let(:asset_exists) { true }

    context 'dev server is running' do
      let(:dev_server_running) { true }

      context 'dev server is using HTTPS' do
        let(:dev_server_uses_https) { true }
        it_behaves_like 'valid SVG'
      end

      context 'dev server is using HTTP' do
        let(:dev_server_uses_https) { false }
        it_behaves_like 'valid SVG'
      end
    end
  end

  context 'asset does not exist' do
    let(:asset_exists) { false }

    context 'dev server is running' do
      let(:dev_server_running) { true }

      context 'dev server is using HTTPS' do
        let(:dev_server_uses_https) { true }
        it_behaves_like 'invalid SVG'
      end

      context 'dev server is using HTTP' do
        let(:dev_server_uses_https) { false }
        it_behaves_like 'invalid SVG'
      end
    end
  end
end
