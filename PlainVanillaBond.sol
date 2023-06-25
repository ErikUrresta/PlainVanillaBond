// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlainVanillaBond is ERC20 {
    address private _issuer;  // Dirección del emisor del bono
    uint256 private _coupon;  // Valor del cupón del bono
    uint256 private _maturity;  // Fecha de vencimiento del bono
    uint256 private _couponPaymentDate;  // Fecha de pago del cupón
    uint256 private _couponPeriod = 180 days;  // Período de pago del cupón en días
    bool private _bondSaleClosed = false;  // Indica si la venta del bono está cerrada

    mapping(address => bool) private _kycComplete;  // Registro de usuarios con KYC completado
    mapping(address => uint256) private _lastCouponPayment;  // Registro de última fecha de pago de cupón para cada usuario

    constructor(uint256 maturity, uint256 coupon)
        ERC20("Vanilla Bond", "vBOND")
    {
        _issuer = msg.sender;
        _maturity = maturity;
        _coupon = coupon;
        _couponPaymentDate = maturity - 2 * _couponPeriod;  // Se asume que el bono se emite 1 año antes de la fecha de vencimiento
    }

    function setKycCompleted(address user) public {
        require(msg.sender == _issuer, "Only the issuer can complete KYC");  // Solo el emisor puede completar el proceso KYC
        _kycComplete[user] = true;
    }

    function closeBondSale() public {
        require(msg.sender == _issuer, "Only the issuer can close bond sale");  // Solo el emisor puede cerrar la venta del bono
        _bondSaleClosed = true;
    }

    function buy(uint256 amount) public payable {
        require(!_bondSaleClosed, "Bond sale is closed");  // Verifica que la venta del bono esté abierta
        require(_kycComplete[msg.sender], "KYC not completed, purchase not allowed");  // Verifica que el usuario haya completado el KYC
        require(msg.value == amount, "Incorrect amount of Ether sent");  // Verifica que la cantidad de Ether enviada sea correcta

        _mint(msg.sender, amount);  // Crea nuevos tokens de bono y los asigna al comprador
    }

    function redeem(uint256 amount) public {
        require(block.timestamp >= _maturity, "Bond has not matured");  // Verifica que el bono haya vencido
        require(balanceOf(msg.sender) >= amount, "Insufficient bond balance");  // Verifica que el balance de bonos del usuario sea suficiente

        _burn(msg.sender, amount);  // Quema (destruye) los tokens de bono del usuario
        payable(msg.sender).transfer(amount);  // Transfiere al usuario el valor equivalente en Ether del bono redimido
    }

    function claimCoupon() public {
        require(_kycComplete[msg.sender], "KYC not completed, coupon claim not allowed");  // Verifica que el usuario haya completado el KYC
        require(_lastCouponPayment[msg.sender] < _couponPaymentDate, "Coupon already paid for this period");  // Verifica que el usuario no haya reclamado el cupón para este período
        require(block.timestamp >= _couponPaymentDate, "Coupon payment is not due yet");  // Verifica que la fecha de pago del cupón haya llegado

        _lastCouponPayment[msg.sender] = block.timestamp;  // Actualiza la última fecha de pago del cupón para el usuario
        payable(msg.sender).transfer(_coupon);  // Transfiere al usuario el valor del cupón en Ether
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == _issuer || to == _issuer, "Secondary market transfers not allowed");  // Solo se permiten transferencias en el mercado secundario entre el emisor y los participantes
        super._beforeTokenTransfer(from, to, amount);
    }
}
