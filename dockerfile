FROM ubuntu:latest

LABEL maintainer="ThisWaySir@github.com"

ENV TZ Asia/Shanghai

ENV LANG en_US.UTF-8

USER karel

RUN apt-get update \
        && apt-get install -y wget curl git ncurses-dev build-essential bzip2 openssh-server python3 python3-pip privoxy golang-1.9 clang cmake zsh \
        && pip3 install -y shadowsocks

# ssh server
#sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd
# set PermitRootLogin yes
RUN sed -i 's/PermitRootLogin.*/PermitRootLogin yes/g' \
    && service ssh restart

# oh my zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
        && chsh -s /bin/zsh

# proxy
RUN echo '{"server":"X.X.X.X", "server_port":XX, "local_address": "127.0.0.1", "local_port":1080, "password":"XX", "timeout":300, "method":"aes-256-cfb", "fast_open": false}' >> /etc/shadowsocks.json \
        && echo 'forward-socks5    /   127.0.0.1:1080 .' >> /etc/privoxy/config \
        && nohup /usr/local/bin/sslocal -c /etc/shadowsocks.json & \
        && nohup /usr/sbin/privoxy /etc/privoxy/config & \
        && echo "export http_proxy='127.0.0.1:8118'" >> ~/.zshrc \
        && echo "export https_proxy='127.0.0.1:8118'" >> ~/.zshrc \
        && echo "export no_proxy='XXXX.com'" >> ~/.zshrc

# golang
RUN export GOROOT=/usr/lib/go-1.9 \
        && mkdir -p ~/code/go \
        && export GOPATH=~/code/go \
        && export PATH=$PATH:$GOROOT/bin:$GOPATH/bin \
        && go get -u github.com/golang/dep/cmd/dep \
        && go install github.com/golang/dep

# port
EXPOSE 22 443 80 9999

# vim 8.0
# ref https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
RUN wget ftp://ftp.home.vim.org/pub/vim/unix/vim-8.0.tar.bz2 \
        && bzip2 -d vim-8.0.tar.bz2 \
        && tar xf vim-8.0.tar \
        && cd vim80/ \
        && ./configure --enable-python3interp=yes --with-python3-config-dir=/usr/lib/python3.5/config-3.5m-x86_64-linux-gnu \
        && make \
        && make install
# ycm
RUN git clone --depth 1  https://github.com/Valloric/YouCompleteMe ~/.vim/bundle/YouCompleteMe \
        && cd ~/.vim/bundle/YouCompleteMe \
        && git submodule update --init --recursive \
        && python3 install.py --clang-completer

RUN cp ~/.vim/bundle/YouCompleteMe/third_party/ycmd/examples/.ycm_extra_conf.py ~/.vim/ \
        && cd ~/.vim/bundle/YouCompleteMe  && cp -r autoload plugin third_party python ~/.vim

RUN echo "let g:ycm_server_python_interpreter='/usr/bin/python3.5'" >> ~/.vimrc \
        && echo "let g:ycm_global_ycm_extra_conf='~/.vim/.ycm_extra_conf.py'" >> ~/.vimrc \
        && echo "let g:ycm_seed_identifiers_with_syntax=1" >> ~/.vimrc \
        && echo "set completeopt-=preview" >> ~/.vimrc

