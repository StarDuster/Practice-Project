function clone::do_clone() {
  local script="url='$1'
print('github' in url or 'bitbucket' in url)"
  local need_proxy=$(python -c "$script")
  local proxy="socks5://localhost:1080"

  if [ "$need_proxy" = "True" ]; then
    export {https,http,all}_proxy=$proxy
    git clone "$1" "$2"
    unset {https,http,all}_proxy
  else
    git clone "$1" "$2"
  fi
}

function clone::parse_url() {
  local script
  script="from urlparse import urlparse
url = '$1'
if url.startswith('git@'):
  print(url.split(':')[1].rstrip('.git'))
elif url.startswith('http'):
  print(urlparse(url).path[1:].rstrip('.git'))"
  python -c "$script"
}

function clone() {
  local target="$HOME/repo/"
  target+="$(clone::parse_url $1)"
  clone::do_clone "$1" "$target"
  cd "$target"
  echo "$target" 
}