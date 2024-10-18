#!/bin/bash

# ���������, ��� ���������� � ����� �������
# ���������� ��������� ��� ������� � ������������� socket.io Server
echo "����������� ������� � ������������� socket.io Server..."
find . -name '*.ts' -exec sed -i 's/import { Server } from '\''socket.io'\'';/import { Server as IOServer } from '\''socket.io'\'';/g' {} \;
find . -name '*.ts' -exec sed -i 's/const io: Server = new Server();/const io: IOServer = new IOServer();/g' {} \;

# ����������� ���� BasketItem � models/relations.ts
echo "����������� ���� BasketItem � models/relations.ts..."
find ./models/relations.ts -exec sed -i 's/typeof BasketItem/BasketItem/g' {} \;

# ���������� �������� bid � ������ �����
echo "���������� �������� 'bid'..."
find ./routes/*.ts -exec sed -i 's/{ data: User; status: string; }/{ data: User; status: string; bid: number; }/g' {} \;

# ����������� �������� � rawBody � server.ts
echo "����������� rawBody � server.ts..."
find ./server.ts -exec sed -i 's/req.rawBody/(req as CustomRequest).rawBody/g' {} \;

# ��������� ������ form-data � ������ ������ getHeaders
echo "��������� form-data � ������ ������ getHeaders..."
npm install form-data
find ./test/api/*.ts -exec sed -i 's/formData.getHeaders()/form.getHeaders()/g' {} \;

echo "��� ����������� �������!"
