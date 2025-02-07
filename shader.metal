#include <metal_stdlib>
using namespace metal;

uint wang_hash(uint seed) {
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

kernel void generateUUID(device uint32_t* uuids [[buffer(0)]],
                        constant uint32_t& prefix [[buffer(1)]],
                        constant uint32_t& timestamp [[buffer(2)]],
                        constant uint32_t& prefix_length [[buffer(3)]],
                        uint id [[thread_position_in_grid]]) {
    uint index = id * 4;

    // Generate random values for each component
    uint seed = wang_hash(timestamp + id);
    uint rand1 = wang_hash(seed);
    uint rand2 = wang_hash(rand1);
    uint rand3 = wang_hash(rand2);
    uint rand4 = wang_hash(rand3);

    // Calculate how many bits to preserve based on prefix length
    uint shift_amount = 32 - (prefix_length * 4); // 4 bits per hex digit

    // First component: combine prefix with random bits
    uuids[index] = (prefix << shift_amount) | (rand1 & ((1 << shift_amount) - 1));

    // Other components are fully random
    uuids[index + 1] = rand2;
    uuids[index + 2] = rand3;
    uuids[index + 3] = rand4;
}