class Item # 商品
end

class Crawler
  def initialize(url)
    @base_url = url # クロール対象ページの1ページ目
    @target_url = @base_url # 現在のクロール対象ページ
    @download_path = ""
    @last_crawled_item_release = last_crawled_item_release()
    @last_item_release = nil
  end
  
  def crawl() # クロール開始
  	while next_url()
  		parse()
  	end
  end

  private
  
  def last_crawled_item_release()
    last_crawled_item_release = nil
    return last_crawled_item_release
  end
  
  def next_url() # 対象URLの次のページ ※"next"は予約語！
  	# 次のページのURLを取得する
  	next_url = nil if has_crawled? # 次のページが存在しないorクロール済みの場合
    if @last_item_release < @last_crawled_item_release # クロール済み
      return true
    else
      return false
    end
  end
  
  def  parse() # 1ページの解析
  	item_list = [] # パースして商品リストを取得する
  	item_list.each do |item|
  	  item_id = "" # 商品ID
  	  if has_not_downloaded?(item_id)
    		item_name = "" # 商品名を取得する（特殊な文字をエスケープ）
    		datetime_str = ""
    		item_release = DateTime.strptime(datetime_str, '%Y-%m-%d')
    		@last_item_release = item_release
    		trial_url = "" # 体験版URLを取得する
    		trial_file = "" # 体験版をダウンロードする
    		# 体験版を解凍する
    		item_folder = "" # ダウンロードしたフォルダ
    		# フォルダ名に商品名を追加する
    	end
  	end
  end

  def has_not_downloaded?(item_id)
    if true # ダウンロードパスににitem_idを含むフォルダがある
      return false
    else
      return true
    end
  end
end

begin
  url = ""
  Crawler.new()

rescue => e
  puts e, e.backtrace
end