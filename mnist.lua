--[[

README: 

A script for fitting a neural network model to the MNIST 
data set. The architecture is
28*28 --> 128 --> 128 --> 9 --> 10-way softmax
and the goal is to use the 9-unit layer as a lower-dimensional
representation of the data.

After fitting the network, its performance on the MNIST test set
is reported, then the data plus 9-dimensional representation
is written to file (for later use in R).

Run with:

th mnist.lua

Post-process in Unix shell by:

cat mnist_dim9.txt | tail -n 1 | tr ' ' '\n' > tmp.txt
mv tmp.txt mnist_dim9.txt


--]]

----------------------------------------------------------------------
-- set-up...

-- where is the data?

path = '/Users/wmoxbury/data/MNIST/'
img_file = 'train-images-idx3-ubyte'
lab_file = 'train-labels-idx1-ubyte'
img_test = 't10k-images-idx3-ubyte'
lab_test = 't10k-labels-idx1-ubyte'

-- and where should the output go?

outfile = 'mnist_dim9.txt'

----------------------------------------------------------------------
-- preliminary function definitions for the MNIST data set:

require 'io'

function bytes_to_int(b4,b3,b2,b1)
    if not b4 then error("Needs four bytes to convert to int", 2) end
    local n = b1 + 256*b2 + 65536*b3 + 16777216*b4
    if n > 2147483647 then n = n - 4294967296 end
    return n
end

function argmax(u)
    local idx = 1
    local maxval = u[idx]
    for i = 2,u:size()[1] do
        if u[i] > maxval then idx = i; maxval = u[idx] end
    end
    return idx
end

function read_data(img_file, lab_file)
    
    -- read label file:
    file, err = io.open(lab_file)
    local magic = bytes_to_int(file:read(4):byte(1,4))
    local n = bytes_to_int(file:read(4):byte(1,4))
    print(magic .. " " .. n)
    local labels = torch.Tensor(n)
    for i = 1,n do
        labels[i] = file:read(1):byte() + 1
    end
    file.close()
    
    -- read image file:
    file, err = io.open(img_file)
    file:seek()
    local magic = bytes_to_int(file:read(4):byte(1,4))
    local m = bytes_to_int(file:read(4):byte(1,4))
    local nx = bytes_to_int(file:read(4):byte(1,4))
    local ny = bytes_to_int(file:read(4):byte(1,4))
    print(magic .. " " .. m .. " " .. nx .. " " .. ny)
    if not n==m then error("Nr labels doesn't match nr images", 2) end
    local images = torch.Tensor(m,1,nx,ny)
    for i = 1,m do
        img = file:read(nx*ny)
        for j = 1,nx do
            for k = 1,ny do
                images[{i,1,j,k}] = img:byte(k+(j-1)*ny)
            end
        end
    end
    file:close()
    
    -- construct data set:
    local dataset = {}
    function dataset:size() 
        return n
    end
    dataset['data'] = images
    dataset['labels'] = labels
        
    return dataset
end

----------------------------------------------------------------------
-- load the data:

print("Reading data:")
print("Training...")
train = read_data(path .. img_file, path .. lab_file)
print("Test...")
test = read_data(path .. img_test, path .. lab_test)

----------------------------------------------------------------------
-- build MLP model:

require 'nn'
model = nn:Sequential()

model:add( nn.Linear(28*28, 128) )
model:add( nn.ReLU() )
model:add( nn.Dropout(0.2) )
model:add( nn.Linear(128, 128) )
model:add( nn.ReLU() )
model:add( nn.Dropout(0.2) )
model:add( nn.Linear(128, 9) )
model:add( nn.ReLU() )
model:add( nn.Dropout(0.2) )
model:add( nn.Linear(9,10) )
model:add( nn.LogSoftMax() )

criterion = nn.ClassNLLCriterion()
trainer = nn.StochasticGradient(model, criterion)

----------------------------------------------------------------------
-- run training:

npts = train['labels']:size()[1]
s = train['data']:size()
dataset_inputs = torch.Tensor(s[1], s[2]*s[3]*s[4])
for i=1,s[1] do dataset_inputs[i] = torch.reshape(train['data'][i], s[2]*s[3]*s[4]) end
dataset_outputs = torch.Tensor(s[1]):copy(train['labels'])

print("Starting training...")
for epoch = 1,200 do
    
    print("Epoch " .. epoch)
    local time = sys.clock()
    
    model:training()
    local lr = 1e-6
    
    for n = 1,npts do
        
        local img = dataset_inputs[{n,{}}]
        local lab = dataset_outputs[{n}]
        
        criterion:forward( model:forward(img), lab )
        model:zeroGradParameters()
        model:backward( img, criterion:backward(model.output, lab) )
        model:updateParameters(lr)
    
    end
    
    time = sys.clock() - time
    print('Time:' .. time)
        
end

----------------------------------------------------------------------
-- check performance of the model against test data set:

s = test['data']:size()
test_inputs = torch.Tensor(s[1], s[2]*s[3]*s[4])
for i=1,s[1] do test_inputs[i] = torch.reshape(test['data'][i], s[2]*s[3]*s[4]) end
test_outputs = torch.Tensor(s[1]):copy(test['labels'])

model:evaluate()
    
results = torch.Tensor(10, 10)
results:zero()
    
for n = 1,test:size() do
        
    img = test_inputs[{n,{}}]
    lab = test_outputs[{n}]
    pred = argmax(model:forward(img))
    results[lab][pred] = results[lab][pred] + 1
    
end

print(results)
print("Accuracy:" .. results:diag():sum() / test['labels']:size()[1])

----------------------------------------------------------------------
-- build data frame of labels + pixels + 9-dimensional model output:

s = dataset_inputs:size()
output = torch.Tensor(s[1], 1 + 9)

for n=1,s[1] do
    current = dataset_inputs[n]
    for j=1,7 do current = model['modules'][j]:updateOutput(current) end
    output[{n,1}] = dataset_outputs[n]
    --for j=1,784 do output[{n,j+1}] = dataset_inputs[{n,j}]/255.0 end
    for j=1,9 do output[{n,j+1}] = current[j] end
end

----------------------------------------------------------------------
-- write the array to disk:

file = torch.DiskFile(path .. outfile, 'w')
file:writeObject(output)
file:close() 

