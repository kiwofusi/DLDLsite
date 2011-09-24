require 'date'
require 'open-uri'
require 'kconv'

require 'rubygems'
require 'hpricot'


			
class Item # 商品
	attr_reader :block
	def initialize(block)
		@block = block
	end
	def validate() # 商品ならselfを、そうでないときはnilを返す
		return nil unless contains_item_info?()
		@item_url = @block.search("dt.work_name a").first["href"]
		@id = @block.search("dt.work_name a").first["href"].match(/product_id\/([\w]+)/)[1] # first...
		puts @id
		@title = escape(@block.search("dt.work_name a").inner_html)
		@maker = escape(@block.search("dd.maker_name a").inner_html)
		@release = DateTime.strptime(@block.search("li.sales_date").inner_html.match(/(\d+)年(\d+)月(\d+)日/)[1..3].join("-"), '%Y-%m-%d')
		@local_archive = nil
		@local_folder = nil
		return self
	end
	
	def download()
		if has_trial?
			trial_url = "" # e.g. http://www.dlsite.com/maniax/work/=/product_id/RJ083875.html => http://trial.dlsite.com/doujin/RJ084000/RJ083993_trial.zip
			page = Hpricot(open(@item_url))
			page.search("div.trial_download a").each do |a|
				a["href"]
				# ダウンロードする
				@local_archive = nil # ダウンロードしたファイル
				extract()
			end
		end
	end
	
	def extract() # あとで
		@local_archive # 解凍する
		@local_folder = nil
		add_item_name_to_folder()
		@local_archive if true # 圧縮ファイルを削除する
	end

	def has_downloaded?()
		if false # ダウンロードパスにitem_idを含むフォルダがある
			return true
		else
			return false
		end
	end

	def has_trial?()
		if false # 体験版アイコンが含まれる
			return true
		else
			return false
		end
	end
	
	private

	def escape(str) # パス名に使えない文字をエスケープする
		return str.gsub(/\n/, "")
	rescue => e
		puts e, e.backtrace
	end
	
	def contains_item_info?()
		if @block.search("dt.work_name").size > 0 # そのブロックに商品情報を含む
			return true
		else
			return false
		end
	end
	
	def add_item_name_to_folder()
		local_folder_path = "" # @local_folder のパス
		new_name = local_folder_path + " " + @title
	end

end

class Crawler
	def initialize(url)
		@base_url = normalize_url(url) # クロール対象ページの1ページ目
		@target_url = @base_url # 現在のクロール対象ページ
		@download_path = ""
		@last_crawled_item_release = DateTime.now-1 # ファイルに保存
		@last_item_release = DateTime.now
	end
	
	def crawl() # クロール開始
		parse() # 1ページ目
		while next_url() # 2ページ目以降
			parse()
		end
	end

	private

	def normalize_url(url) # URLを整える
		return url.gsub(/\/$/, "") + "/page/1" # 末尾の / を削除してページ追加
	end
	
	def next_url() # 対象URLの次のページ ※nextは予約語！
		# 次のページのURLを取得する
		if @last_item_release < @last_crawled_item_release # クロール済み
			@target_url = nil
		else
			@target_url.gsub!(/\/page\/(\d+)/) { "/page/#{$1.to_i+1}" } # ブロックでしか書けない？
			# cf. 正規表現のメタ文字 http://www.namaraii.com/rubytips/?%A5%D1%A5%BF%A1%BC%A5%F3%A5%DE%A5%C3%A5%C1
			@target_url = nil
		end
	rescue => e
		@target_url = nil
		puts e, e.backtrace
	end
	
	def parse() # 1ページの解析
		page = Hpricot(open(@target_url))
		# パースして商品リストを取得する
		item_list = page.search("div#search_result_list table tr")
		return @target_url = nil if item_list.size < 1
		i = 0
		item_list.each do |block|
			if item = Item.new(block).validate
				next if item.has_downloaded? # スキップ
			end
			break if i > 2 || !(i+=1)
		end
	end

end

begin
	Dir::chdir(File.dirname(__FILE__)) # カレントディレクトリをソースファイルの場所にする cf. http://d.hatena.ne.jp/kasei_san/20090210/p1 http://d.hatena.ne.jp/yasuoy017/20091124
	puts Dir::pwd
	
	url = "http://www.dlsite.com/maniax/fsr/=/language/jp/sex_category/male/ana_flg/off/age_category%5B0%5D/general/age_category%5B1%5D/r15/age_category%5B2%5D/adult/work_category%5B0%5D/doujin/order%5B0%5D/release_d/work_type%5B0%5D/SOU/work_type_name%5B0%5D/%C2%B2%C2%BB%3C%C2%BA%C3%AE%C3%89%C3%8A/genre_and_or/or/options_and_or/or/per_page/100/show_type/n/"
	url = ARGV[0] || url
	
	Crawler.new(url).crawl()

rescue => e
	puts e, e.backtrace
end