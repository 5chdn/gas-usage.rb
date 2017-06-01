#!/usr/bin/env ruby

require 'rubygems'
require 'ethereum.rb'
require 'terminfo'
require 'colorize'

def init
  begin
    @ipc = Ethereum::IpcClient.new ARGV[0], false
    parse_result @ipc.web3_client_version
    @blocks = {}
    @previous = -999
  rescue Errno::ENOENT, Errno::EINVAL
    printf "Invalid IPC path or none supplied, aborting.\n\n"
    printf "Usage:\n\truby gas-usage.rb /path/to/jsonrpc.ipc\n\n"
    exit 137
  end
end

def parse_result response
  result = response['result']
end

def get_blocks current
  while @previous <= current
    block = parse_result @ipc.eth_get_block_by_number(@previous, false)
    @blocks[@previous] = {
      number: block["number"].to_i(16),
      gasLimit: block["gasLimit"].to_i(16),
      gasUsed: block["gasUsed"].to_i(16),
      utilization: (block["gasUsed"].to_i(16).to_f / block["gasLimit"].to_i(16).to_f)
    }
    @previous += 1
  end
  @previous = current
end

def render current
  height = TermInfo.screen_size.first - 5
  width = TermInfo.screen_size.last - 12
  out = "Ethereum network gas usage visualization\t["
  out += "###".light_green
  out += "   ]: low\n"
  out += "========================================\t["
  out += "###".light_green
  out += "##".light_yellow
  out += " ]: high\n"
  out += "                                        \t["
  out += "###".light_green
  out += "##".light_yellow
  out += "#".light_red
  out += "]: full\n\n"
  @blocks.each do | n, b |
    if n > current - height
      num = n.to_s
      util = b[:utilization] * width.to_f
      out += "#{num}: ["
      for i in 0..width
        if i <= util.round
          if i < width * 0.50
            out += "#".light_green
          elsif i < width * 0.90
            out += "#".light_yellow
          else
            out += "#".light_red
          end
        else
          out += " ".light_black
        end
      end
      out += "]\n"
    end
  end
  out
end

init

loop do
  current = parse_result @ipc.eth_block_number
  current = current.to_i 16
  if @previous < 0
    @previous = current - 16
  end
  get_blocks current
  system "clear" or system "cls"
  vis = render(current)
  printf vis
  sleep 15.9
end
