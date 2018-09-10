# coding: utf-8
Encoding.default_external = 'utf-8'

begin # require
	require 'date'
	require 'open-uri'
	require 'kconv'
	require 'fileutils'

	require 'rubygems'
	require 'hpricot'
	require 'zipruby'
rescue LoadError => e
	puts e, e.backtrace
end

class Item # 商品
	def initialize(block)
		@block = block
	end
	def validate() # 商品ならselfを、そうでないときはnilを返す
		return nil unless contains_item_info?()
		@url = @block["href"]
		@id = @block["href"].match(/product_id\/([\w]+)/)[1] # first...
		@title = dir_escape(@block.inner_html)
		@archive_file = ""
		@download_dir = "./download/"
		return self
	end
	
	def download()
		trial_url = "" # e.g. http://www.dlsite.com/maniax/work/=/product_id/RJ083875.html => http://trial.dlsite.com/doujin/RJ084000/RJ083993_trial.zip
		page = Hpricot(open(@url))
		page.search("div.trial_download a").each do |a|
			puts @archive_file = File::basename(a["href"])
			open("http:" + a["href"]) do |ar| # "http:" + 
				open(@download_dir + @archive_file, "w+b") do |f|
					f.print ar.read
				end
			end
			decompress()
		end
	end
	
	def decompress()
		print "  decompressing...".tosjis
		@decompress_dir = @download_dir + dir_escape(@id + " " + @title) + "/"
		Zip::Archive.open(@download_dir + @archive_file) do |archives| # 解凍する
			FileUtils.makedirs(@decompress_dir)
			archives.each do |ar|
				new_dir = @decompress_dir + File::dirname(file_escape(ar.name))
				FileUtils.makedirs(new_dir)
				unless ar.directory?
					output = @decompress_dir + file_escape(ar.name)
					open(output, "w+b") do |output|
						output.print ar.read
					end
				end
			end
		end
		File::delete(@download_dir + @archive_file) if true # 圧縮ファイルを削除する
		puts "ok".tosjis
	end

	def downloaded?()
		if Dir::glob(@download_dir + @id + " *").size > 0 # ダウンロードパスにIDを含むフォルダがある（フォルダ名のカスタマイズ未対応）
			return true
		else
			return false
		end
	end
	
	private

	def file_escape(str) # ファイル名はそのまま使える
		return str.tosjis
	end
	def dir_escape(str) # 「タイトル」に含まれる禁止文字をエスケープする
		# /\:*?"<>|{} http://support.microsoft.com/kb/903301/ja
		return str.gsub(/\n/, "").gsub(/\//, "／").gsub(/\\/, "￥").gsub(/:/, "：").gsub(/\*/, "＊").gsub(/\?/, "？").gsub(/"/, "''").gsub(/</, "＜").gsub(/>/, "＞").gsub(/\|/, "｜").tosjis # 文字化け /([―|ソ|噂|欺|圭|構|蚕|十|申|貼|能|表|暴|予|禄|兔])/ http://www.nishishi.com/blog/2006/02/garbled_charact.html
		# .gsub(/([―|ソ|噂|欺|圭|構|蚕|十|申|貼|能|表|暴|予|禄|兔])/, "\\1")
	rescue => e
		puts e, e.backtrace
	end
	
	def contains_item_info?()
	  return (@block["href"] \
	    && @block["href"].match("/work/=/product_id/") \
	  	&& @block.inner_text.size > 2)
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
		  puts "next page"
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
		  puts "last_item_release: #@last_item_release"
		  puts "last_crawled_item_release: #@last_crawled_item_release"
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
		item_list = page.search("//a")
		return @target_url = nil if item_list.size < 1
		item_list.each do |block|
			item = Item.new(block).validate
			next if item.nil? || item.downloaded? # スキップ
			item.download
		end
	end

end


def main()
	Dir::chdir(File.dirname(__FILE__)) # カレントディレクトリをソースファイルの場所にする cf. http://d.hatena.ne.jp/kasei_san/20090210/p1 http://d.hatena.ne.jp/yasuoy017/20091124
	
	url = "http://www.dlsite.com/maniax/fsr/=/language/jp/sex_category/male/ana_flg/off/age_category%5B0%5D/general/age_category%5B1%5D/r15/age_category%5B2%5D/adult/work_category%5B0%5D/doujin/order%5B0%5D/release_d/work_type%5B0%5D/SOU/work_type_name%5B0%5D/%C2%B2%C2%BB%3C%C2%BA%C3%AE%C3%89%C3%8A/genre_and_or/or/options_and_or/or/per_page/100/show_type/n/"
	url = ARGV[0] || url
	
	Crawler.new(url).crawl()

	puts "end"
rescue => e
	puts e, e.backtrace
end

main
