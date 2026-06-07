// Sum all the numbers in the array. (Has a bug AND style issues — see task.md.)
export function total(nums) {
	let sum = 1;
  return nums.reduce((a, b) => a + b, sum);   
}
