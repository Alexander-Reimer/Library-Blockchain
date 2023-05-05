
using Dates
mutable struct Block #erzeugt den Block mit den Infos(buch,benutzer, etc.)
    buch::Int
    benutzer::String
    ausleiheDatum::Int
    vorHash::Int
end

function newBlock(Block, buch, benutzer, ausleiheDatum, Genesis, IDString) #erstellt einen neuen Block und pushed ihn in allBlocks
    b = Block(buch, benutzer, ausleiheDatum, Genesis)
    println(b)
    io = open(IDString * "NewBlock.txt", write=true)
        BlockVector = []
        push!(BlockVector, string(b.buch))
        push!(BlockVector, string(b.benutzer))
        push!(BlockVector, string(b.ausleiheDatum))
        
        write(io, string(BlockVector))
        println(string(BlockVector))
    close(io)
end

function getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    newBlocks = []
    for i = 1:length(IDRegister)
        if IDRegister[i] != 3
            io = open(string(i) * "NewBlock.txt")
            content = readline(io)
            close(io)
            b = stringToBlock(content, ownHash)
            if b != nothing
                if b != alreadyGottenBlocks[i]
                    push!(allBlocks, b)
                    alreadyGottenBlocks[i] = b
                end
            end
        end
    end
end

function createHash(allBlocks) #macht aus der Liste mit allen Blöcken(allBlocks) eine Liste mit den Hashes(hashes)
    hashes = zeros(Int, 0)
    checksum1 = 0
    checksum2 = 0
    for i = 1:length(allBlocks)
        checksum1 = mod(checksum1 + allBlocks[i].buch, 255)
        checksum2 = mod(checksum1 + checksum2, 255)
        checksum1 = mod(checksum1 + StringToInteger(allBlocks[i].benutzer), 255)
        checksum2 = mod(checksum1 + checksum2, 255)
        checksum1 = mod(checksum1 + allBlocks[i].ausleiheDatum, 255)
        checksum2 = mod(checksum1 + checksum2, 255)
        checksum1 = mod(checksum1 + allBlocks[i].vorHash, 255)
        checksum2 = mod(checksum1 + checksum2, 255)
        push!(hashes, checksum2)
    end
    return hashes
end

function publishHash(ownHash, ID, hacked, IDRegister)
    IDString = string(ID)
    io = open(IDString * ".txt", read = true, create=true)
        content = readline(io)
    close(io)

    if IDRegister[ID] == 3
        println("Diese ID ("*IDString*") wurde gebannt. Das Programm wird abgebrochen. Bitte wende dich an den Support.")
        return true
    elseif content == "banned"
        println("Diese ID ("*IDString*") wurde gebannt. Das Programm wird abgebrochen. Bitte wende dich an den Support.")
        return true
    else
        io = open(IDString * ".txt", write = true)
            write(io, string(ownHash))
        close(io)
        return false
    end
end

function getCurrentHashes(currentHashes, IDs, IDRegister)
    for i = 1:length(IDs)
        a = string(i)
        io = open("Z:\\Alexander Reimer\\Desktop\\Hashes\\" * a * ".txt", read = true)
        content = readline(io)
        if IDRegister[i] == 3
            push!(currentHashes, 0)
        elseif content == "banned"
            println("Die ID " * a * " wurde gebannt und wird in Zukunft ignoriert.")
            push!(currentHashes, 0)
            IDRegister[i] = 3
        elseif content == ""
            if IDRegister[i] != 2
                println("Die ID " * a * " hat keinen Hash veröffentlicht und wird deswegen vorerst ignoriert.")
                IDRegister[i] = 2
            end
            push!(currentHashes, 0)
        else
            hashInt = tryparse(Int, content)
            if hashInt == nothing
                hashInt = 0
                println("Die ID " * a * " hat einen unlesbaren Hash veröffentlicht und wird deswegen ignoriert.")
                IDRegister[i] = 3
            end
            push!(currentHashes, hashInt)
        end
        close(io)
    end
    return currentHashes
end

function TestIfHacked(currentHashes, ID, IDRegister, correctHashes, acceptanceRange, tooSlowRange)

    validHashes = []
    for i = 1:length(currentHashes)
        if IDRegister[i] == 0
            push!(validHashes, currentHashes[i])
        end
    end

    currentCorrectHash = findMostCommonValue(validHashes)

    if length(correctHashes) == 0
        push!(correctHashes, currentCorrectHash)
    else
        if currentCorrectHash != correctHashes[length(correctHashes)]
            push!(correctHashes, currentCorrectHash)
        end
    end


    while length(correctHashes) < acceptanceRange + tooSlowRange
        pushfirst!(correctHashes, currentCorrectHash)
    end

    while length(correctHashes) > acceptanceRange + tooSlowRange
        deleteat!(correctHashes, 1)
    end

    for i = 1:length(currentHashes)
        if IDRegister[i] == 0 || IDRegister[i] == 1
            IDRegister[i] = 3

            for i2 = 1:acceptanceRange
                if currentHashes[i] == correctHashes[length(correctHashes)-i2+1]
                    IDRegister[i] = 0
                end
            end

            if IDRegister[i] == 3
                for i2 = acceptanceRange+1:acceptanceRange+tooSlowRange
                    if currentHashes[i] == correctHashes[length(correctHashes)-i2+1]
                        IDRegister[i] = 1
                    end
                end
            end

            if IDRegister[i] == 3
                println("Die ID " * string(i) * " wurde gebannt und wird in Zukunft ignoriert!")
            end
        end
    end
end

function StringToInteger(s) #macht string(s) zu Int(ss)
    ss = 0
    for i = 1:length(s)
        c = s[i]
        ss += Int(c)
    end
    return ss
end

function isFoundIn(input, element, var) #vergleicht ob var = Element element von input ist
    if input[element] == var
        return true
    else
        return false
    end
end

function findMostCommonValue(currentHashes) #vergleicht, welcher Wert in currentHashes am häufigsten vorkommt
    amounts = []
    hashes = []
    push!(amounts, 1)
    push!(hashes, currentHashes[1])

    for i = 2:length(currentHashes)
        for i2 = 1:length(hashes)
            if isFoundIn(hashes, i2, currentHashes[i])
                amounts[i2] += 1
            else
                push!(hashes, currentHashes[i])
                push!(amounts, 1)
            end
        end
    end

    biggest = amounts[1]
    element2 = 1
    for i3 = 2:length(amounts)
        if amounts[i3] > biggest
            biggest = amounts[i3]
            element2 = i3
        end
    end
    return hashes[element2]
end

function unban(ownHash, IDs, IDRegister)
    for i = 1:length(IDs)
        io = open(string(i) * ".txt", write=true)
        write(io, string(ownHash))
        close(io)
    end
    for i = 1:length(IDRegister)
        IDRegister[i] = 0
    end
end

function stringToArray(string)
    stringArray = split(string, ", ")
    stringArray[1] = SubString(stringArray[1], 5)
    stringArray[length(stringArray)] = SubString(stringArray[length(stringArray)], 1:length(stringArray[length(stringArray)])-1)
    array = []
    for i = 1:length(stringArray)
        push!(array, parse(Int8, stringArray[i]))
    end
    return array
end

function stringToBlock(string, ownHash)
    splitter = '"' * ", " * '"'
    stringArray = split(string, splitter)
    stringArray[1] = SubString(stringArray[1], 6)
    stringArray[length(stringArray)] = SubString(stringArray[length(stringArray)], 1:length(stringArray[length(stringArray)])-2)
    
    
    Buch = tryparse(Int8, stringArray[1])
    if Buch == nothing
        b = nothing
    else
        Benutzer = stringArray[2]
        Datum = tryparse(Int8, stringArray[1])
        if Datum == nothing
            b = nothing
        else
          b = Block(Buch, Benutzer, Datum, ownHash)  
        end
    end
    return b
end


function main()

    correctHashes = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 77, 98]
    IDs = [1, 2, 3]
    ID = 2
    IDString = string(ID)

    io = open(IDString * "banned.txt", read=true)
        str = readline(io)
    close(io)

    #=
    IDRegister definitions:
    0 = normal
    1 = too slow
    2 = no Hash published
    3 = banned
    1, 2 and 3 are ignored until they are 0
    only 1 and 2 can be 0 again, if they publish one of the right hashes again.
    =#
    IDRegister = []
    if str != ""
        IDRegister = stringToArray(str)
    end

    while length(IDs) > length(IDRegister)
        push!(IDRegister, 0)
    end

    currentHashes = []
    currentHashes = getCurrentHashes(currentHashes, IDs, IDRegister)
    println(currentHashes)

    

    #Genesis = findMostCommonValue(currentHashes)
    Genesis = 69
    ownHash = Genesis
    hashes = zeros(Int, 0)
    allBlocks = Array{Block}(undef, 0)
    alreadyGottenBlocks = Array{Block}(undef, 0)
    b = Block(-10, "Niemand", 12011324, 00)
    alreadyGottenBlocks = [b, b, b]
    println(b)
    println(alreadyGottenBlocks)
    println(allBlocks)
    newBlock(Block, 01, "Matteo", 05102019, Genesis, IDString)
    println(allBlocks)
    getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    println(allBlocks)

    hashes = createHash(allBlocks)
    ownHash = hashes[length(hashes)]

    newBlock(Block, 02, "Alex", 08092020, Genesis, IDString)
    getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    hashes = createHash(allBlocks)
    ownHash = hashes[length(hashes)]

    newBlock(Block, 03, "Arthur der Farmasgagfser", 08112019, Genesis, IDString)
    getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    hashes = createHash(allBlocks)
    ownHash = hashes[length(hashes)]

    newBlock(Block, 04, "Test", 08112019, Genesis, IDString)
    getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    hashes = createHash(allBlocks)
    ownHash = hashes[length(hashes)]

    newBlock(Block, 13, "Johannes", 10112019, Genesis, IDString)
    getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
    hashes = createHash(allBlocks)
    ownHash = hashes[length(hashes)]


    for i = 1:100
        getNewBlocks(IDRegister, alreadyGottenBlocks, allBlocks, ownHash)
        hashes = zeros(Int, 0)
        hashes = createHash(allBlocks)
        ownHash = hashes[length(hashes)]
        unban(ownHash, IDs, IDRegister)

        hacked = false
        hacked = publishHash(ownHash, ID, hacked, IDRegister)

        if hacked == true #wird wieder gebannt, falls schon gebannt wurde
            io = open(IDString * ".txt", write=true)
            a = "banned"
                write(io, a)
            close(io)

            IDRegister[ID] = 3

            break
        else
            currentHashes = []
            currentHashes = getCurrentHashes(currentHashes, IDs, IDRegister)
            acceptanceRange = 3
            tooSlowRange = 5
            TestIfHacked(currentHashes, ID, IDRegister, correctHashes, acceptanceRange, tooSlowRange)
            if IDRegister[ID] == 3
                io = open(IDString * ".txt", write=true)
                a = "banned"
                    write(io, a)
                close(io)
                break
            end
        end

        io = open(IDString * "banned.txt", write=true)
            write(io, string(IDRegister))
        close(io)

    end
    currentHashes = []
    println(getCurrentHashes(currentHashes, IDs, IDRegister))
    io = open(IDString * "banned.txt", write=true)
        write(io, string(IDRegister))
    close(io)

end  # main

main()