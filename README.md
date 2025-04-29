# OnFlow Finance Smart Contracts

Welcome to the official smart contract repository for **OnFlow Finance** — an on-chain funding platform empowering SME growth through transparent, decentralized vaults.

This repository contains the **core smart contracts** that govern OnFlow’s investment and repayment mechanisms.

---

## 📜 Contracts Included

| Contract Name      | Description                                                                          |
|---------------------|--------------------------------------------------------------------------------------|
| `OnFlowVault.sol`    | ERC-4626 based vault contract managing SME fundraising and installment repayments.   |
| `VaultFactory.sol`   | Factory contract deploying new vaults securely using the minimal proxy pattern.     |

---

## 🚀 Getting Started

If you wish to **test** or **experiment** with these contracts locally:

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/onflow-contracts.git
Install dependencies (depending on your development framework)

bash

forge install   # Foundry users
npm install     # Hardhat users
Compile contracts

bash

forge build
or
bash

npx hardhat compile
Deploy locally Adjust constructor parameters carefully before testing deployments on local blockchain environments.

⚠️ Disclaimer
These smart contracts are provided for educational and testing purposes only.
They are not audited for production usage. Deploying them live requires thorough security audits, business logic adjustments, and a deep understanding of the underlying system architecture.

📄 License
This project is licensed under the MIT License.
Please see the LICENSE file for full terms.

🌐 About OnFlow Finance
OnFlow Finance enables real-world businesses to access blockchain-based funding without traditional banking friction.
We build tokenized, transparent, and accessible financial products for the modern economy.

Built with ❤️ to empower business growth.
---

# 📄 LICENSE

```text
MIT License

Copyright (c) 2025 OnFlow Finance

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell  
copies of the Software, and to permit persons to whom the Software is  
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included  
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL  
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER  
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  
SOFTWARE.