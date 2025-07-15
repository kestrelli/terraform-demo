from flask import Flask, request, jsonify
import logging

# 配置日志记录
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('app.log')
    ]
)

app = Flask(__name__)

@app.route('/', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def handle_request():
    """获取真实客户端IP（适用于四层CLB）"""
    client_ip = request.remote_addr
    headers = dict(request.headers)
    
    # 记录关键信息
    logging.info(f"Received {request.method} request from {client_ip}")
    logging.debug("Full headers: %s", headers)
    
    # 返回包含客户端真实IP的响应
    return jsonify({
        "message": "Real client IP captured",
        "client_ip": client_ip,  # 直接返回真实IP
        "method": request.method,
        "headers": headers
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)