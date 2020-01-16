pragma solidity ^0.4.0; // Versao do Solidity

contract GuardaLoteria {
    address dono; // Endereco do dono do contrato
    string nomeDono;
    uint dataInicio;
    
    // Estrutura de sorteio
    struct Sorteio {
        uint data;
        uint numeroSorteado;
        address remetente;
        uint countPalpites;
    }
    
    Sorteio[] sorteios; // Array dos sorteios realizados
    mapping(address=> uint) palpites; // Mapeia um Endereco para um numero inteiro positivo
    address[] palpiteiros;
    address[] ganhadores;

    constructor (string _nome) public{
        dono = msg.sender; // Recebe Endereco de quem realizou o deploy
        nomeDono = _nome;
        dataInicio = now;
    }
    
    modifier apenasDono(){
        require(msg.sender == dono, "Somente o dono do contrato pode fazer isso!");
        _;
    }
    
     modifier excetoDono(){
        require(msg.sender != dono, "Exceto o dono do contrato pode fazer isso!");
        _;
    }
    
    // Eventos do contrato
    event TrocoEnviado(address pagador, uint troco);
    event PalpiteRegistrado(address remetente, uint palpite);
    event SorteioPostado(uint resultado);
    event PremiosEnviados(uint premioTotal, uint premio);

    function enviarPalpite(uint palpiteEnviado) public payable excetoDono(){
        require((palpiteEnviado >= 1) && (palpiteEnviado <= 4), "Voce tem que escolher um numero entre 1 e 4!");
        require(palpites[msg.sender] == 0, "Voce so pode registrar um palpite por sorteio!");
        require(msg.value > 1 ether, "A taxa para palpitar eh de 1 Ether!");
        
        // calcula e envia o troco
        uint troco = msg.value - 1 ether;
        if(troco > 0){
            msg.sender.transfer(troco);
            emit TrocoEnviado(msg.sender, troco);
        }
        
        // registra o palpite
        palpites[msg.sender] = palpiteEnviado;
        palpiteiros.push(msg.sender);
        emit PalpiteRegistrado(msg.sender, palpiteEnviado);
    }
    
    function getMeuPalpite() public view excetoDono() returns(uint palpite){
        require(palpites[msg.sender] > 0, "Voce nao tem palpites ainda para esse sorteio");
        
        return palpites[msg.sender];
    }
    
    function sortear() public apenasDono() returns(uint _numeroSorteado){
        require(palpiteiros.length >= 1, "O sorteio deve ter no minimo 1 palpiteiro!");
        
        // sortear um numero
        uint8 numeroSorteado = uint8(keccak256(abi.encodePacked(blockhash(block.number-1))))/64+1; // 1
        
        sorteios.push(Sorteio({
            data: now,
            numeroSorteado: numeroSorteado,
            remetente: msg.sender,
            countPalpites: palpiteiros.length
        }));
        emit SorteioPostado(numeroSorteado);
        
        // procurando ganhadores
        for(uint p = 0; p < palpiteiros.length; p++){
            address palpiteiro = palpiteiros[p];
            if(palpites[palpiteiro] == numeroSorteado){
                ganhadores.push(palpiteiro);
            }
            delete palpites[palpiteiro];
        }
        
        // premio total do sorteio
        uint premioTotal = address(this).balance;
        
        if(ganhadores.length > 0){
            uint premio = premioTotal/ganhadores.length;
            
            // envia premio
            for(p = 0; p < ganhadores.length; p++){
                ganhadores[p].transfer(premio);
            }
            emit PremiosEnviados(premioTotal, premio);
        }
        // Reseta o sorteio
        delete palpiteiros;
        delete ganhadores;
        
        return numeroSorteado;
    }
    
    // Invalida o contrato e envia saldo para o dono do contrato
    function kill() public {
        require(msg.sender == dono, "Somente o dono do contrato pode usar o kill!");
        selfdestruct(dono);
    }
}